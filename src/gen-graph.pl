#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-
# -*- tab-width: 2
# -*- indent-tabs-mode: nil

use strict;
use warnings;

my $nl = "\n";
my $tbl = do $ARGV[0];

my $edges = [];
while (my ($key, $val_tbl) = each (%{$$tbl{'all'}})) {
  foreach my $val (sort keys %$val_tbl) {
    push @$edges, [ $val, $key ];
  }
}

print
  "digraph {" . $nl .
  "  graph [ rankdir = LR ]; " . $nl .
  "  node [ shape = rect, style = rounded ]; " . $nl .
  $nl;

my $nodes = {};
foreach my $path (keys %{$$tbl{'all'}}) {
  if ($path =~ m=^(.+/-rt/.+)$=) {
    my $node = $1;
    $$nodes{$node} = 1;
  }
}
foreach my $node (sort keys %$nodes) {
  print "  \"$node\" [ color = blue ];" . $nl;
}
#print join(";\n", @$edges) . ";\n";
foreach my $edge (@$edges) {
  print "  \"$$edge[0]\" -> \"$$edge[1]\"";

  # * -> hh, * -> dk.cc
  if ($$edge[1] =~ /\.hh$/) {
    print " [ style = dashed ]";
  } elsif ($$edge[1] =~ /\.dk\.cc$/) {
    print " [ style = dashed ]";
  }
  print ";\n";
}
#
print
  "  subgraph { graph [ rank = same ];" . $nl .
  $nl;
foreach my $input (sort keys $$tbl{'inputs'}) {
  print "    \"$input\";" . $nl;
}
print "  }" . $nl;
#
print
  "  subgraph { graph [ rank = same ];" . $nl .
  $nl;
foreach my $path (keys %{$$tbl{'all'}}) {
  if ($path =~ /\.dk\.json$/) {
    print "    \"$path\";" . $nl;
  }
}
print "  }" . $nl;
print "}" . $nl;
