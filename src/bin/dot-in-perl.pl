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
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

my $g = do $ARGV[0];

#print &Dumper($g);

my $edge_type_from_graph_type = { 'digraph' => '->',
                                  'graph' =>   '--' };
sub dot_stmt_default {
  my ($g, $ds) = @_;
  my $stmts = [];
  foreach my $d (@$ds) {
    my $stmt = "$d \[";
    my $delim = '';
    my $keys = [sort keys %{$$g{$d}}];
    if (scalar @$keys) {
      my $first = shift @$keys;
      $stmt .= " $first = \"$$g{$d}{$first}\"";
      $delim = ', ';
      foreach my $key (@$keys) {
        $stmt .= "$delim\n"  . (' ' x length($d . " \[")) . " $key = \"$$g{$d}{$key}\"";
      }
    }
    if (scalar @$keys) {
      $stmt .= "\n" . "\]";
    } else {
      $stmt .= " \]";
    }

    push @$stmts, $stmt;
  }
  return $stmts;
}
sub dot_stmt {
  my ($graph_type, $pair, $extra) = @_;
  my $lhs;
  my $edge_type = $$edge_type_from_graph_type{$graph_type};
  if ($extra && $$extra{'no-quote-nodes'}) {
    $lhs = join(" $edge_type ", @{$$pair[0]});
  } else {
    $lhs = '"' . join("\" $edge_type \"", @{$$pair[0]}) . '"';
  }
  my $rhs = '';
  my $d = '';
  while (my ($key, $val) = each %{$$pair[1]}) {
    #$val =~ s/\/\\\\/g;
    $val =~ s/"/\\"/g;
    $rhs .= $d . $key . ' = "' . $val . '"';
    $d = ', ';
  }
  if ($rhs) {
    $rhs = '[ ' . $rhs . ' ]';
  }
  return "$lhs $rhs";
}
my $indent = '  ';

my $output = $$g{'-type'} . " \"" . $$g{'-name'} . "\" {\n";

my $stmts = &dot_stmt_default($g, [ 'graph', 'edge', 'node' ]);
foreach my $stmt (@$stmts) {
  $stmt =~ s/\n/"\n" . '  '/eg;
  $output .= $indent . $stmt . ";\n";
}
$output .= "\n";

foreach my $pair (@{$$g{'-stmts'}}) {
  $output .= $indent . &dot_stmt($$g{'-type'}, $pair) . ";\n";
}
$output .= '}' . "\n";

print $output;
