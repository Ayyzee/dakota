#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;
use sort 'stable';
use Cwd;

my $gbl_prefix;
my $nl = "\n";

sub dk_prefix {
  my ($path) = @_;
  $path =~ s|//+|/|;
  $path =~ s|/\./+|/|;
  $path =~ s|^./||;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    &dk_prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!" . $nl;
  }
}

BEGIN {
  $gbl_prefix = &dk_prefix($0);
  unshift @INC, "$gbl_prefix/lib";
};
use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use dakota::dakota;
use dakota::parse;
use dakota::util;

use Data::Dumper;
$Data::Dumper::Terse =     1;
$Data::Dumper::Deepcopy =  1;
$Data::Dumper::Purity =    1;
$Data::Dumper::Useqq =     1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent =    1;   # default = 2

use Getopt::Long qw(GetOptionsFromArray);
$Getopt::Long::ignorecase = 0;

sub add_node {
  my ($current_node,
      $output,
      $inputs,
      $cmd) = @_;
  my $result = {
    'output' => $output,
    'cmd'    => $cmd,
  };
  foreach my $input (@$inputs) {
    $$result{'inputs'}{$input} = undef;
  }
  $$current_node{'inputs'}{$output} = $result;
  return $result;
}
sub src_asts {
  my ($srcs) = @_;
  return [ map { &ast_path_from_dk_path($_) } @$srcs ];
}
sub lib_asts {
  my ($libs) = @_;
  return [ map { &ast_path_from_ctlg_path(&ctlg_path_from_so_path($_)) } @$libs ];
}
sub gen_inputs_ast_graph {
  my ($inputs) = @_;
  my $root = {};
  my ($srcs, $libs) = ([], []);
  foreach my $input (sort @$inputs) {
    if ($input =~ /\.dk$/) {
      push @$srcs, $input;
    } else {
      push @$libs, $input;
    }
  }
  my $build_dir =  &build_dir();
  my $source_dir = &source_dir();
  my $lib_asts = &lib_asts($libs);
  my $target_hdr_node = &add_node($root,
                                  &target_hdr_path(),
                                  [ &target_inputs_ast_path() ],
                                  [ 'dakota', '--target', 'hdr', "--var=source_dir=$source_dir", "--var=build_dir=$build_dir" ]);
  my $target_inputs_ast_node = &add_node($target_hdr_node,
                                         &target_inputs_ast_path(),
                                         [ &target_srcs_ast_path(), @$lib_asts ],
                                         [ 'dakota', '--action', 'merge', "--var=source_dir=$source_dir", "--var=build_dir=$build_dir", '--output', '$@', '$?' ]);
  foreach my $lib (@$libs) {
    my $lib_ctlg = &ctlg_path_from_so_path($lib);
    my $lib_ast = &ast_path_from_ctlg_path($lib_ctlg);
    my $lib_ast_node = &add_node($target_inputs_ast_node,
                                 $lib_ast,      # output
                                 [ $lib_ctlg ], # inputs
                                 [ 'dakota', '--action', 'parse', "--var=source_dir=$source_dir", "--var=build_dir=$build_dir", '--output', '$@', '$<' ]);
    my $lib_ctlg_node = &add_node($lib_ast_node,
                                  $lib_ctlg, # output
                                  [ $lib ],  # inputs
                                  [ 'dakota-catalog', '--output', '$@', '$<' ]);
  }
  ###
  my $src_asts = &src_asts($srcs);
  my $target_srcs_ast_node = &add_node($target_inputs_ast_node,
                                       &target_srcs_ast_path(),
                                       [ @$src_asts ],
                                       [ 'dakota', '--action', 'merge', "--var=source_dir=$source_dir", "--var=build_dir=$build_dir", '--output', '$@', '$?' ]);
  foreach my $src (@$srcs) {
    my $src_ast = &ast_path_from_dk_path($src);
    my $src_ast_node = &add_node($target_srcs_ast_node,
                                 $src_ast,
                                 [ $src ],
                                 [ 'dakota', '--action', 'parse', "--var=source_dir=$source_dir", "--var=build_dir=$build_dir", '--output', '$@', '$<' ]);
  }
  return $root;
}
sub dump_dot {
  my ($node) = @_;
  my $result = '';
  $result .= 'digraph {' . $nl;
  $result .= '  graph [ rankdir = LR, dir = back, nodesep = 0.03 ];' . $nl;
  $result .= '  node  [ shape = rect, style = rounded, height = 0, width = 0 ];' . $nl;
  $result .= $nl;
  $result .= &dump_dot_recursive($node);
  $result .= '}' . $nl;
  if (1) {
    my $prefix = &longest_common_prefix(&source_dir(), &intmd_dir());
    $result =~ s=$prefix==g; # hack to make the graph less noisy
  }
  return $result;
}
sub dump_dot_recursive {
  my ($node) = @_;
  my $result = '';
  my $output = $$node{'output'};
  foreach my $input (sort keys %{$$node{'inputs'}}) {
    if ($$node{'inputs'}{$input}) {
      $result .= &dump_dot_recursive($$node{'inputs'}{$input});
    } else {
      $result .= "  \"$input\" [ color = blue ];" . $nl;
    }
    if ($output) {
      $result .= "  \"$output\" -> \"$input\";" . $nl;
    }
  }
  return $result;
}
sub dump_make {
  my ($node) = @_;
  my $result = '';
  $result .= '.PHONY: all' . $nl
    . $nl;
  $result .= 'all:';
  foreach my $input (keys %{$$node{'inputs'}}) {
    $result .= " $input";
  }
  $result .= $nl . $nl;
  $result .= &dump_make_recursive($node);
  return $result;
}
sub dump_make_recursive {
  my ($node) = @_;
  my $result = '';
  my $output = $$node{'output'};
  if ($output) {
    my $num_inputs = scalar keys %{$$node{'inputs'}};
    my $d = " \\\n";
    $result .= "$output:" . $d;
    $result .= join($d, sort keys %{$$node{'inputs'}}) . $nl;
    $result .= "\t" . join(' ', @{$$node{'cmd'}}) . $nl;
  }
  foreach my $input (sort keys %{$$node{'inputs'}}) {
    if ($$node{'inputs'}{$input}) {
      $result .= &dump_make_recursive($$node{'inputs'}{$input});
    }
  }
  return $result;
}
sub write_build_mk {
  my ($root, $output) = @_;
  open(my $fh, '>', $output);
  print $fh &dump_make($root);
  close($fh);
  #print $output . $nl;
}
sub write_build_dot {
  my ($root, $output) = @_;
  open(my $fh, '>', $output);
  print $fh &dump_dot($root);
  close($fh);
  #print $output . $nl;
}
sub cmd_info_from_argv {
  my ($argv) = @_;
  my $root_cmd = {
    'opts' => {
    'var' => [],
    }
  };
  &GetOptionsFromArray($argv, $$root_cmd{'opts'},
                       'path-only',
                       'var=s',
                      );
  $$root_cmd{'inputs'} = $argv; # this should always be empty
  &set_env_vars($$root_cmd{'opts'}{'var'});
  delete $$root_cmd{'opts'}{'var'};
  return $root_cmd;
}
sub start {
  my ($argv) = @_;
  my $cmd_info = &cmd_info_from_argv($argv);
  my $intmd_dir = &intmd_dir();
  my $build_mk = $intmd_dir . '/build.mk';
  &make_dirname($build_mk);
  if ($$cmd_info{'opts'}{'path-only'}) {
    print $build_mk . $nl;
    exit 0;
  }
  my $parts = $intmd_dir . '/parts.txt';
  die &basename($0) . ": error: missing $parts" . $nl if ! -e $parts;
  undef $/;
  open(my $fh, '<', $parts);
  my $inputs = [ split(/\s+/, <$fh>) ];
  close($fh);
  my $root = &gen_inputs_ast_graph($inputs);
  &write_build_mk($root, $build_mk);
  if (1) {
    my $build_dot = $intmd_dir . '/build.dot';
    &write_build_dot($root, $build_dot);
  }
  #print STDERR &Dumper($root);
}
unless (caller) {
  &start(\@ARGV);
}
1;
