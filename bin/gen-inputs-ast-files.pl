#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse =     1;
$Data::Dumper::Deepcopy =  1;
$Data::Dumper::Purity =    1;
$Data::Dumper::Useqq =     1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent =    1;   # default = 2

my $nl = "\n";

### <<
my $source_dir;
my $build_dir;
my $intmd_dir;
sub path_split {
  my ($path) = @_;
  my $parts = [split /\//, $path];
  my $name = pop @$parts;
  my $dir = join '/', @$parts;
  $dir = '.' if $dir eq "";
  return ($dir, $name);
}
sub dirname {
  my ($path) = @_;
  my ($dir, $name) = &path_split($path);
  return $dir;
}
sub basename {
  my ($path) = @_;
  my ($dir, $name) = &path_split($path);
  return $name;
}
sub target_path {
  my ($name) = @_;
  return $intmd_dir . '/z/' . $name =~ s=^$source_dir/==r;
}
sub path {
  my ($name) = @_;
  return $intmd_dir . '/' . $name =~ s=^$source_dir/==r;
}
sub lib_path {
  my ($name) = @_;
  return $intmd_dir . '/' . &basename($name);
}
sub target_srcs_ast_path {
  return &target_path('srcs.ast');
}
sub target_inputs_ast_path {
  return &target_path('inputs.ast');
}
sub ast_path_from_dk_path {
  my ($dk_path) = @_;
  return &path($dk_path) . '.ast';
}
sub ast_path_from_ctlg_path {
  my ($ctlg_path) = @_;
  return $ctlg_path . '.ast';
}
sub ctlg_path_from_so_path {
  my ($so_path) = @_;
  return &lib_path($so_path) . '.ctlg';
}
### >>
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
  my $lib_asts = &lib_asts($libs);
  my $target_inputs_ast_node = &add_node($root,
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
# found at http://linux.seindal.dk/2005/09/09/longest-common-prefix-in-perl
sub longest_common_prefix {
  my $path_prefix = shift;
  for (@_) {
    chop $path_prefix while (! /^$path_prefix/);
  }
  return $path_prefix;
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
    my $prefix = &longest_common_prefix($source_dir, $intmd_dir);
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
sub write_inputs_ast_mk {
  my ($inputs, $output) = @_;
  my $root = &gen_inputs_ast_graph($inputs);
  open(my $fh, '>', $output);
  print $fh &dump_make($root);
  close($fh);
  #print $output . $nl;
  return $root;
}
sub write_inputs_ast_dot {
  my ($root, $output) = @_;
  open(my $fh, '>', $output);
  print $fh &dump_dot($root);
  close($fh);
  #print $output . $nl;
}
sub start {
  my ($argv) = @_;
  die if scalar @$argv != 2;
  $source_dir = $ARGV[0];
  $build_dir =  $ARGV[1];
  $intmd_dir = &dirname(&dirname($build_dir)) . '/intmd/' . &basename($build_dir);
  my $parts = $intmd_dir . '/parts.txt';
  die &basename($0) . ": error: missing $parts" . $nl if ! -e $parts;
  undef $/;
  open(my $fh, '<', $parts);
  my $inputs = [ split(/\s+/, <$fh>) ];
  close($fh);
  my $inputs_ast_mk = $intmd_dir . '/inputs-ast.mk';
  my $root = &write_inputs_ast_mk($inputs, $inputs_ast_mk);
  if (1) {
    my $inputs_ast_dot = $intmd_dir . '/inputs-ast.dot';
    &write_inputs_ast_dot($root, $inputs_ast_dot);
  }
  #print STDERR &Dumper($root);
}
unless (caller) {
  &start(\@ARGV);
}
1;
