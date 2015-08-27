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

my $g = { '-type' => 'digraph',
          '-name' => 'dot-grammar-fsm',
          'graph' => { 'rankdir' => 'LR',
                       'center' => 'true',
                       'label' => '\G',
                       'fontcolor' => 'red',
                       'fontsize' => '16',
          },
          'edge'  => { 'fontname' => 'Courier',
                       'fontsize' => '16' },
          'node'  => { 'shape' => 'circle',
                       'width' => '0.6',
                       'fontsize' => '16' },
          '-stmts' => [ [ [ 'st' ], { 'label' => '', 'style' => 'invis' } ],
                        [ [ 'st', '01' ], { 'label' => '' } ],
                        [ [ '01', '02' ], { 'label' => 'digraph|graph' } ],
                        [ [ '01', '03' ], { 'label' => 'digraph|graph' } ],
                        [ [ '02', '03' ], { 'label' => '"name"' } ],
                        [ [ '03', '04' ], { 'label' => '{' } ],
                        [ [ '04' ], { 'shape' => 'doublecircle' } ],
                        [ [ '04', '02' ], { 'label' => 'subgraph' } ],
                        [ [ '04', '03' ], { 'label' => 'subgraph', 'style' => 'dashed' } ],
                        [ [ '04', '04' ], { 'label' => '}' } ],
                        [ [ '04', '05' ], { 'label' => '"node"' } ],
                        [ [ '04', '06' ], { 'label' => 'graph|edge|node' } ],
                        [ [ '05', '04' ], { 'label' => ';', 'style' => 'dashed' } ],
                        [ [ '05', '05' ], { 'label' => '->|-- "node"' } ],
                        [ [ '05', '07' ], { 'label' => '[' } ],
                        [ [ '06', '07' ], { 'label' => '[' } ],
                        [ [ '07', '08' ], { 'label' => '<attr> = "value"' } ],
                        [ [ '07', '09' ], { 'label' => ']' } ],
                        [ [ '08', '07' ], { 'label' => ',', 'style' => 'dashed' } ],
                        [ [ '08', '09' ], { 'label' => ']' } ],
                        [ [ '09', '04' ], { 'label' => ';', 'style' => 'dashed' } ],
                      ]
};

#print &Dumper($g);

sub dot_stmt {
  my ($pair, $extra) = @_;
  my $lhs;
  if ($extra && $$extra{'no-quote-nodes'}) {
    $lhs = join(' -> ', @{$$pair[0]});
  } else {
    $lhs = '"' . join('" -> "', @{$$pair[0]}) . '"';
  }
  my $rhs = '';
  my $d = '';
  while (my ($key, $val) = each %{$$pair[1]}) {
    $val =~ s/"/\\"/g;
    $rhs .= $d . $key . ' = "' . $val . '"';
    $d = ', ';
  }
  if ($rhs) {
    $rhs = ' [ ' . $rhs . ' ]';
  }
  return ($lhs, $rhs);
}

my $indent = '  ';
my $output = '';
$output .= $$g{'-type'} . ' ' . '"' . $$g{'-name'} . '"' . ' {' . "\n";

my ($lhs, $rhs);
($lhs, $rhs) = &dot_stmt([ [ 'graph' ], $$g{'graph'} ], { 'no-quote-nodes' => 1 });
$output .= $indent . $lhs . $rhs . ';' . "\n";

($lhs, $rhs) = &dot_stmt([ [ 'edge' ], $$g{'edge'} ], { 'no-quote-nodes' => 1 });
$output .= $indent . $lhs . $rhs . ';' . "\n";

($lhs, $rhs) = &dot_stmt([ [ 'node' ], $$g{'node'} ], { 'no-quote-nodes' => 1 });
$output .= $indent . $lhs . $rhs . ';' . "\n";

foreach my $pair (@{$$g{'-stmts'}}) {
  my ($lhs, $rhs) = &dot_stmt($pair);
  $output .= $indent . $lhs . $rhs . ';' . "\n";
}
$output .= '}' . "\n";

print $output;
