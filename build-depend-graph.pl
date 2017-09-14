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
undef $/;

my $build_dir = 'zzz/build';
my $target_build_dir = $build_dir . '/z';

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
sub basename {
  my ($path) = @_;
  my $name = $path =~ s=^(.*/)*(.+)$=$2=r;
  return $name;
}
sub target_path {
  my ($name) = @_;
  #return $target_build_dir . '/' . $name;
  return 'b/z/' . &basename($name);
}
sub ast_path_from_dk_path {
  my ($dk_path) = @_;
  #return $build_dir . '/' . &basename($dk_path) . '.ast';
  return 'b/' . &basename($dk_path) . '.ast';
}
sub ast_path_from_so_path {
  my ($so_path) = @_;
  #return $build_dir . '/' . &basename($so_path) . '.ctlg.ast';
  return 'b/' . &basename($so_path) . '.ctlg.ast';
}
sub dump_dot {
  my ($node) = @_;
  my $output = $$node{'output'};
  foreach my $input (keys %{$$node{'inputs'}}) {
    if ($$node{'inputs'}{$input}) {
      &dump_dot($$node{'inputs'}{$input});
    }
    if ($output) {
      print "  \"$output\" -> \"$input\";" . $nl;
    }
  }
}

my $inputs = [split(/\s+/, <STDIN>)];
my $srcs = [];
my $libs = [];

foreach my $input (@$inputs) {
  $input = &basename($input);
  if ($input =~ /\.dk$/) {
    push @$srcs, $input;
  } else {
    push @$libs, $input;
  }
}

my $lib_asts = [];
foreach my $lib (@$libs) {
  push @$lib_asts, &ast_path_from_so_path($lib);
}
my $src_asts = [];
foreach my $src (@$srcs) {
  push @$src_asts, &ast_path_from_dk_path($src);
}
my $root = {};

my $target_h_node = &add_node($root,
                              &target_path('target.h'),
                              [ &target_path('inputs.ast') ],
                              [ '<cmd>', '--output', &target_path('target.h'), &target_path('inputs.ast') ],
                            );
my $inputs_ast_node = &add_node($target_h_node,
                                &target_path('inputs.ast'),
                                [ &target_path('srcs.ast'), @$lib_asts ],
                                [ '<cmd>', '--output', &target_path('inputs.ast'), &target_path('srcs.ast'), @$lib_asts ],
                              );
foreach my $lib (@$libs) {
  my $lib_ast = &ast_path_from_so_path($lib);
  &add_node($inputs_ast_node,
            $lib_ast,
            [ $lib ],
            [ '<cmd>', '--output', &target_path($lib_ast), $lib ],
          );
}
my $srcs_ast_node = &add_node($inputs_ast_node,
                              &target_path('srcs.ast'),
                              [ @$src_asts ],
                              [ '<cmd>', '--output', &target_path('srcs.ast'), @$src_asts ],
                            );
foreach my $src (@$srcs) {
  my $src_ast = &ast_path_from_dk_path($src);
  &add_node($srcs_ast_node,
            $src_ast,
            [ $src ],
            [ '<cmd>', '--output', &target_path($src_ast), $src ],
          );
}
print STDERR &Dumper($root);

print 'digraph {' . $nl;
print '  graph [ rankdir = LR, dir = back ];' . $nl;
print '  node  [ shape = rect, style = rounded ];' . $nl;
&dump_dot($root);
print '}' . $nl;
