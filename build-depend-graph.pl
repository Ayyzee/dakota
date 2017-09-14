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

### <<
sub basename {
  my ($path) = @_;
  my $name = $path =~ s=^(.*/)*(.+)$=$2=r;
  return $name;
}
sub target_path {
  my ($name) = @_;
  return 'b/z/' . &basename($name);
}
sub target_srcs_ast_path {
  return &target_path('srcs.ast');
}
sub target_inputs_ast_path {
  return &target_path('inputs.ast');
}
sub target_hdr_path {
  return &target_path('target.h');
}
sub ast_path_from_dk_path {
  my ($dk_path) = @_;
  return 'b/' . &basename($dk_path) . '.ast';
}
sub ast_path_from_so_path {
  my ($so_path) = @_;
  return 'b/' . &basename($so_path) . '.ctlg.ast';
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
sub asts {
  my ($inputs) = @_;
  return [ values %$inputs ];
}
sub gen_target_hdr_graph {
  my ($inputs) = @_;
  my $root = {};
  my ($srcs, $libs) = ({}, {});
  foreach my $input (sort @$inputs) {
    if ($input =~ /\.dk$/) {
      $$srcs{$input} = &ast_path_from_dk_path($input);
    } else {
      $$libs{$input} = &ast_path_from_so_path($input);
    }
  }
  my $target_hdr_node = &add_node($root,
                                  &target_hdr_path(),
                                  [ &target_inputs_ast_path() ],
                                  [ '<cmd>', '--target-hdr', '--output', &target_hdr_path(),
                                    &target_inputs_ast_path() ]);
  ###
  my $target_inputs_ast_node = &add_node($target_hdr_node,
                                         &target_inputs_ast_path(),
                                         [ &target_srcs_ast_path(), @{&asts($libs)} ],
                                         [ '<cmd>', '--merge-ast', '--output', &target_inputs_ast_path(),
                                           &target_srcs_ast_path(), @{&asts($libs)} ]);
  while (my ($lib, $lib_ast) = each %$libs) {
    &add_node($target_inputs_ast_node,
              $lib_ast,
              [ $lib ],
              [ '<cmd>', '--parse-lib', '--output', $lib_ast, $lib ]);
  }
  ###
  my $target_srcs_ast_node = &add_node($target_inputs_ast_node,
                                       &target_srcs_ast_path(),
                                       [ @{&asts($srcs)} ],
                                       [ '<cmd>', '--merge-ast', '--output', &target_srcs_ast_path(),
                                         @{&asts($srcs)} ]);
  while (my ($src, $src_ast) = each %$srcs) {
    &add_node($target_srcs_ast_node,
              $src_ast,
              [ $src ],
              [ '<cmd>', '--parse-src', '--output', $src_ast, $src ]);
  }
  return $root;
}

my $inputs = [ split(/\s+/, <STDIN>) ];
$inputs = [ map { &basename($_) } @$inputs ];
my $root = &gen_target_hdr_graph($inputs);

if (1) {
  sub dump_dot {
    my ($node) = @_;
    my $result = '';
    my $output = $$node{'output'};
    foreach my $input (sort keys %{$$node{'inputs'}}) {
      if ($$node{'inputs'}{$input}) {
        $result .= &dump_dot($$node{'inputs'}{$input});
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
    my $output = $$node{'output'};
    if ($output) {
      $result .= "$output:";
      foreach my $input (sort keys %{$$node{'inputs'}}) {
        if ($output) {
          $result .= " $input";
        }
      }
      $result .= $nl;
      $result .= "\t" . join(' ', @{$$node{'cmd'}}) . $nl;
    }
    foreach my $input (sort keys %{$$node{'inputs'}}) {
      if ($$node{'inputs'}{$input}) {
        $result .= &dump_make($$node{'inputs'}{$input});
      }
    }
    return $result;
  }
  print 'digraph {' . $nl;
  print '  graph [ rankdir = LR, dir = back, nodesep = 0.03 ];' . $nl;
  print '  node  [ shape = rect, style = rounded, height = 0 ];' . $nl;
  print &dump_dot($root);
  print '}' . $nl;

  print STDERR &dump_make($root);
  #print STDERR &Dumper($root);
}
