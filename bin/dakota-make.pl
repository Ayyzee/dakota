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

sub cmd_info_from_argv {
  my ($argv) = @_;
  my $root_cmd = {
    'opts' => {
    'var' => [],
    }
  };
  &GetOptionsFromArray($argv, $$root_cmd{'opts'},
                       'parts=s',
                       'path-only',
                       'target-path=s',
                       'var=s',
                      );
  $$root_cmd{'inputs'} = $argv; # this should always be empty
  &set_env_vars($$root_cmd{'opts'}{'var'});
  delete $$root_cmd{'opts'}{'var'};
  $$root_cmd{'parts'} = &parts($$root_cmd{'opts'}{'parts'});
  return $root_cmd;
}
sub target_o_path {
  my $result = &target_build_dir() . '/target.cc.o';
  return $result;
}
sub is_dk_o_path {
  my ($path) = @_;
  return $path =~ /\.dk\.o$/;
}
sub is_target_o_path {
  my ($path) = @_;
  return $path eq &target_o_path();
}
sub o_path_from_dk_path {
  my ($dk_path) = @_;
  my $result = &build_dir() . '/' . &basename($dk_path) . '.o';
  return $result;
}
sub gen_dot {
  my ($rules) = @_;
  my $result = '';
  $result .= 'digraph {' . $nl;
  $result .= '  graph [ rankdir = LR, dir = back, nodesep = 0.03 ];' . $nl;
  $result .= '  node  [ shape = rect, style = rounded, height = 0, width = 0 ];' . $nl;
  $result .= $nl;
  $result .= &gen_dot_body($rules);
  $result .= '}' . $nl;
  if (1) {
    my $prefix = &longest_common_prefix(&source_dir(), &intmd_dir());
    $result =~ s=$prefix==g; # hack to make the graph less noisy
  }
  return $result;
}
sub gen_dot_body {
  my ($rules) = @_;
  my $result = '';
  my $root = $$rules[0][0][0];
  my $target_hdr_path = &target_hdr_path();
  my $target_src_path = &target_src_path();
  my $target_o_path =   &target_o_path();
  if (1) {
  $result .=
    "  \"$root\" [ color = green ];" . $nl .
    "  \"$target_hdr_path\" [ color = magenta ];" . $nl .
    "  \"$target_src_path\" [ color = magenta ];" . $nl .
    "  \"$target_o_path\" [ color = magenta ];" . $nl .
    $nl;
  for (my $i = 0; $i < scalar @$rules; $i++) {
    for (my $j = 0; $j < scalar @{$$rules[$i]}; $j++) {
      for (my $k = 0; $k < scalar @{$$rules[$i][$j]}; $k++) {
        my $path = $$rules[$i][$j][$k];
        if (0) {
        } elsif (&is_dk_path($path)) {
          $result .= "  \"$path\" [ color = blue ];" . $nl;
        } elsif (&is_so_path($path)) {
          $result .= "  \"$path\" [ color = green ];" . $nl;
        }
      }
    }
  }
  }
  foreach my $rule (@$rules) {
    my $tgts =               $$rule[0];
    my $prereqs =            $$rule[1];
    my $order_only_prereqs = $$rule[2];
    foreach my $tgt (@$tgts) {
      foreach my $prereq (@$prereqs) {
        $result .= "  \"$tgt\" -> \"$prereq\"";
        if (0) {
        } elsif (&is_target_o_path($tgt)) {
          $result .= ' [ color = magenta ]';
        } elsif (&is_dk_o_path($tgt) && &is_dk_path($prereq)) {
          $result .= ' [ color = blue ]';
        }
        $result .= ';' . $nl;
      }
      foreach my $prereq (@$order_only_prereqs) {
        $result .= "  \"$tgt\" -> \"$prereq\" [ color = gray, style = dashed ]";
        ###
        $result .= ';' . $nl;
      }
    }
  }
  return $result;
}
sub gen_make {
  my ($rules) = @_;
  my $result = '';
  my $root = $$rules[0][0][0];
  $result .=
    ".PHONY: all" . $nl .
    $nl .
    "all: $root" . $nl;
  ###
  $result .= &gen_make_body($rules);
  ###
  return $result;
}
sub gen_make_body {
  my ($rules) = @_;
  my $result = '';
  foreach my $rule (@$rules) {
    my $tgts =               $$rule[0];
    my $prereqs =            $$rule[1];
    my $order_only_prereqs = $$rule[2];
    my $recipe =             $$rule[3];
    my $d = $nl;
    foreach my $tgt (@$tgts) {
      $result .= $d . $tgt;
      $d = " \\\n";
    }
    $result .= ' :';
    foreach my $prereq (@$prereqs) {
      $result .= $d . $prereq;
    }
    if (scalar @$order_only_prereqs) {
      $result .= ' |';
      foreach my $prereq (@$order_only_prereqs) {
        $result .= $d . $prereq;
      }
    }
    $result .= $nl;
  }
  return $result;
}
sub write_target_mk {
  my ($str) = @_;
  my $output = &intmd_dir() . '/target.mk';
  open(my $fh, '>', $output);
  print $fh $str;
  close($fh);
  #print $output . $nl;
}
sub write_target_dot {
  my ($str) = @_;
  my $output = &intmd_dir() . '/target.dot';
  open(my $fh, '>', $output);
  print $fh $str;
  close($fh);
  #print $output . $nl;
}
sub start {
  my ($argv) = @_;
  my $cmd_info = &cmd_info_from_argv($argv);
  my $target_path = $$cmd_info{'opts'}{'target-path'};
  #print &Dumper($cmd_info);
  my $rules = [];
  my $dk_paths = [];
  my $so_paths = [];
  my $so_ctlg_ast_paths = [];
  my $dk_o_paths = [];
  my $dk_ast_paths = [];
  foreach my $path (@{$$cmd_info{'parts'}}) {
    if (&is_dk_path($path)) {
      &add_last($dk_paths, $path);

      my $dk_o_path = &o_path_from_dk_path($path);
      &add_last($dk_o_paths, $dk_o_path);

      my $dk_ast_path = &ast_path_from_dk_path($path);
      &add_last($dk_ast_paths, $dk_ast_path);
    } else {
      &add_last($so_paths, $path);
      my $so_ctlg_path =     &ctlg_path_from_so_path($path);
      my $so_ctlg_ast_path = &ast_path_from_ctlg_path($so_ctlg_path);
      &add_last($so_ctlg_ast_paths, $so_ctlg_ast_path);
    }
  }
  my $target_hdr_path =        &target_hdr_path();
  my $target_src_path =        &target_src_path();
  my $target_o_path =          &target_o_path();
  my $target_inputs_ast_path = &target_inputs_ast_path();
  my $target_srcs_ast_path =   &target_srcs_ast_path();
  &add_last($rules, [[$target_path], $dk_o_paths, [], []]);
  &add_last($rules, [[$target_path], [$target_o_path], [], []]);
  &add_last($rules, [[$target_o_path], [$target_hdr_path, $target_src_path], [], []]);
  &add_last($rules, [$dk_o_paths, [], [$target_hdr_path], []]); # using order-only prereqs
  foreach my $dk_path (@$dk_paths) {
    my $dk_o_path = &o_path_from_dk_path($dk_path);
    &add_last($rules, [[$dk_o_path], [$dk_path], [], []]);
  }
  &add_last($rules, [[$target_hdr_path, $target_src_path], [$target_inputs_ast_path], [], []]);
  &add_last($rules, [[$target_inputs_ast_path], [$target_srcs_ast_path, @$so_ctlg_ast_paths], [], []]);
  &add_last($rules, [[$target_srcs_ast_path], [@$dk_ast_paths], [], []]);
  foreach my $dk_path (@$dk_paths) {
    my $dk_ast_path = &ast_path_from_dk_path($dk_path);
    &add_last($rules, [[$dk_ast_path], [$dk_path], [], []]);
  }
  foreach my $so_path (@$so_paths) {
    my $so_ctlg_path = &ctlg_path_from_so_path($so_path);
    my $so_ctlg_ast_path = &ast_path_from_ctlg_path($so_ctlg_path);
    &add_last($rules, [[$so_ctlg_ast_path], [$so_ctlg_path], [], []]);
    &add_last($rules, [[$so_ctlg_path], [$so_path], [], []]);
  }
  my $target_mk = &gen_make($rules);
  &write_target_mk($target_mk);
  if (1) {
    my $target_dot = &gen_dot($rules);
    &write_target_dot($target_dot);
    #print $target_dot;
  }
  #print STDERR &Dumper($rules);
  #print STDERR $target_mk;
}
unless (caller) {
  &start(\@ARGV);
}
1;
