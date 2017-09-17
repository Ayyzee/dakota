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
sub path {
  my ($name) = @_;
  return 'b/' . &basename($name);
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
  return &path($ctlg_path) . '.ast';
}
sub ctlg_path_from_so_path {
  my ($so_path) = @_;
  return &path($so_path) . '.ctlg';
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
                                         [ 'dakota.pm', '--merge', '--output', &target_inputs_ast_path(),
                                           &target_srcs_ast_path(), @$lib_asts ]);
  foreach my $lib (@$libs) {
    my $lib_ctlg = &ctlg_path_from_so_path($lib);
    my $lib_ast = &ast_path_from_ctlg_path($lib_ctlg);
    my $lib_ast_node = &add_node($target_inputs_ast_node,
                                 $lib_ast,      # output
                                 [ $lib_ctlg ], # inputs
                                 [ 'dakota.pm', '--parse', '--output', $lib_ast, $lib_ctlg ]);
    my $lib_ctlg_node = &add_node($lib_ast_node,
                                  $lib_ctlg, # output
                                  [ $lib ],  # inputs
                                  [ 'dakota-catalog', '--output', $lib_ctlg, $lib ]);
  }
  ###
  my $src_asts = &src_asts($srcs);
  my $target_srcs_ast_node = &add_node($target_inputs_ast_node,
                                       &target_srcs_ast_path(),
                                       [ @$src_asts ],
                                       [ 'dakota.pm', '--merge', '--output', &target_srcs_ast_path(),
                                         @$src_asts ]);
  foreach my $src (@$srcs) {
    my $src_ast = &ast_path_from_dk_path($src);
    my $src_ast_node = &add_node($target_srcs_ast_node,
                                 $src_ast,
                                 [ $src ],
                                 [ 'dakota.pm', '--parse', '--output', $src_ast, $src ]);
  }
  return $root;
}
sub dump_dot {
  my ($node) = @_;
  my $result = '';
  $result .= 'digraph {' . $nl;
  $result .= '  graph [ rankdir = LR, dir = back, nodesep = 0.03 ];' . $nl;
  $result .= '  node  [ shape = rect, style = rounded, height = 0, width = 0 ];' . $nl;
  $result .= '  node  [ fontnames = ps, fontname = courier ];' . $nl
    . $nl;
  $result .= &dump_dot_recursive($node);
  $result .= '}' . $nl;
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
  $result .= 'all:';
  foreach my $input (keys %{$$node{'inputs'}}) {
    $result .= " $input";
  }
  $result .= $nl . $nl;
  $result .= &dump_make_recursive($node);
  ###
  return $result;
}
sub dump_make_recursive {
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
      $result .= &dump_make_recursive($$node{'inputs'}{$input});
    }
  }
  return $result;
}
sub start {
  my ($argv) = @_;
  my $inputs = [ map { &basename($_) } @$argv ];
  my $root = &gen_inputs_ast_graph($inputs);
  print STDOUT &dump_dot($root);
  print STDERR &dump_make($root);
  #print STDERR &Dumper($root);
}
unless (caller) {
  &start(\@ARGV);
}
1;
