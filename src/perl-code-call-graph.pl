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
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

$main::block = qr{
                   \{
                   (?:
                     (?> [^{}]+ )         # Non-braces without backtracking
                   |
                     (??{ $main::block }) # Group with matching braces
                   )*
                   \}
               }x;

my $data = {
  'excluded-use' => do "perl-code-call-graph-excluded-use.pl",
  'defn' => {},
  'defn-lines-max' => 0,
  'defn-lines-total' => 0,
  'name-tbl' => {},
  'use' => {},
  'use-total' => 0,
  'summary' => {
    'defn-count' => 0,
    'use-count' => 0,
  },
};
sub add_defn {
  my ($data, $name, $body) = @_;
  my $lines = $body =~ tr/\n//;
  $$data{'defn'}{$name} = $lines;
  if ($$data{'defn-lines-max'} < $lines) {
    $$data{'defn-lines-max'} = $lines;
  }
  $$data{'defn-lines-total'} += $lines;
  $$data{'summary'}{'defn-count'}++;
}
sub add_use {
  my ($data, $name) = @_;
  if (!exists $$data{'use'}{$name}) {
    $$data{'use'}{$name} = 0;
  }
  $$data{'use'}{$name}++;
  $$data{'summary'}{'use-count'}++;
}
sub add_name {
  my ($data, $name) = @_;
  my $base = (split(/::/, $name))[-1];
  if ($name ne $base) {
    if (!exists $$data{'name-tbl'}{$base}{$name}) {
      $$data{'name-tbl'}{$base}{$name} = 0;
    }
    $$data{'name-tbl'}{$base}{$name}++;
  }
}
my $tbl1 = {};
my $tbl2 = {};

undef $/;
while (<>) {
  while ($_ =~ m/\bsub\s+([\w:]+)\s*($main::block)/g) {
    my $node1 = $1; my $body = $2;
    &add_defn($data, $node1, $body);
    &add_name($data, $node1);
    while ($body =~ m/&([\w:]+)\s*\(/g) {
      my $node2 = $1;
      &add_use($data, $node2);
      &add_name($data, $node2);
      if (!exists $$tbl1{$node1}{$node2}) {
        $$tbl1{$node1}{$node2} = 0;
      }
      $$tbl1{$node1}{$node2}++;
    }
  }
}
sub fqfy {
  my ($data, $name) = @_;
  my $result = $name;
  if ($$data{'name-tbl'}{$name}) {
    $result = $$data{'name-tbl'}{$name};
    print STDERR "NAME: $name, RESULT: $result\n";
  }
  return $result;
}
foreach my $n1 (keys %$tbl1) {
  my $subtbl = $$tbl1{$n1};
  $n1 = &fqfy($data, $n1);
  foreach my $n2 (keys %$subtbl) {
    $n2 = &fqfy($data, $n2);
    $$tbl2{$n1}{$n2} = 1;
  }
}
#use Data::Dumper; print STDERR &Dumper($$data{'defn'});
use Data::Dumper; print STDERR &Dumper($$data{'summary'});
#use Data::Dumper; print &Dumper($tbl1);
#use Data::Dumper; print STDERR &Dumper($tbl2);
#use Data::Dumper; print STDERR &Dumper($name_tbl);
if (1) {
  my $ambigs = {};
  print "digraph {\n";
  print "  graph [ rankdir = LR, size = \"8,10.5\", center = true, ratio = expand ];\n";
  print "  node [ shape = rect, style = rounded, fontname = \"Courier-Oblique\" ];\n";

  my $lines_ave = scalar $$data{'defn-lines-total'} / (scalar keys %{$$data{'defn'}});
  foreach my $node (sort keys %{$$data{'defn'}}) {
    if (!exists $$data{'excluded-use'}{$node}) {
      my $lines = $$data{'defn'}{$node};
      my $node_height = sprintf("%.2f", log($lines / length($node)));
      if (0 < $node_height) {
        print " \"$node\" [ height = \"$node_height\" ];\n";
      }
    }
  }
  print "\n";
  foreach my $node1 (sort keys %$tbl2) {
    if (!exists $$data{'excluded-use'}{$node1}) {
      my $subtbl = $$tbl2{$node1};
      #$node1 = &fqfy($data, $node1);
      foreach my $node2 (sort keys %$subtbl) {
        if (!exists $$data{'excluded-use'}{$node2}) {
          #$node2 = &fqfy($data, $node2);
          print "  \"$node1\" -> \"$node2\";\n";
          if (!$$ambigs{$node1} && $$data{'uses'}{$node1}) {
            if (exists $$data{'name-tbl'}{$node1} && 1 < scalar keys %{$$data{'name-tbl'}{$node1}}) {
              print STDERR "WARNING: ambiguous subroutine name '$node1'\n";
              $$ambigs{$node1} = 1;
            }
          }
          if (!$$ambigs{$node2} && $$data{'uses'}{$node2}) {
            if (exists $$data{'name-tbl'}{$node2} && 1 < scalar keys %{$$data{'name-tbl'}{$node2}}) {
              print STDERR "WARNING: ambiguous subroutine name '$node2'\n";
              $$ambigs{$node2} = 1;
            }
          }
        }
      }
    }
  }
  print "}\n";
}
