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

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $default_graph_type = 'digraph';
my $edge_type_from_graph_type = { 'digraph' => '->',
                                  'graph' =>   '--' };

my $opts = {};
&GetOptions($opts,
            'output=s',
            'stdout'
          );

my $out;
if ($$opts{'stdout'}) {
  $out = *STDOUT;
}
foreach my $arg (@ARGV) {
  my $g = do $arg || die "$!";
  if (!$$opts{'stdout'}) {
    my $name = $$opts{'output'} ||= "$arg.dot";
    open($out, ">", $name) || die "$!";
  }
  if (!$$g{'-type'}) {
    $$g{'-type'} = $default_graph_type;
  }
  if (!$$g{'-name'}) {
    $$g{'-name'} = $$opts{'output'} ||= "$arg.dot";
  }
  my $result = &dump_dot($g);
  print $out $result;
  if (!$$opts{'stdout'}) {
    close($out);
  }
}
sub dump_dot {
  my ($g) = @_;
  my $result = $$g{'-type'} . ' ' . &dquote_str($$g{'-name'}) . " {\n";
  my $stmts = &dot_stmts($g);
  $result .= &indent_stmts($stmts);
  $result .= "}\n";
  return $result;
}
sub dquote_node {
  my ($val) = @_;
  my $special = { 'graph' => 1,
                  'edge' => 1,
                  'node' => 1 };
  return $val if $$special{$val};
  return &dquote_str($val);
}
sub dquote_str {
  my ($val) = @_;
  return $val if $val =~ m/^".*"$/;
  #$val =~ s/\\/\\\\/g;
  $val =~ s/"/\\"/g;
  $val = "\"$val\"";
  return $val;
}
sub dot_stmts {
  my ($g) = @_;
  my $graph_type = $$g{'-type'} ||= $default_graph_type;
  my $stmts = $$g{'-stmts'}; # must exist
  my $result = [];
  foreach my $pair (@$stmts) {
    my $nodes = $$pair[0];
    $nodes = [ map { &dquote_node($_) } @$nodes ];
    my $edge_type = $$edge_type_from_graph_type{$graph_type};
    my $stmt = join(" $edge_type ", @$nodes);
    my $attrs = [sort keys %{$$pair[1]}];
    if (scalar @$attrs) {
      $stmt .= ' [ ';
      my $d = '';
      foreach my $key (@$attrs) {
        my $val = &dquote_str($$pair[1]{$key});
        $stmt .= $d . "$key = $val";
        $d = ', ';
      }
      $stmt .= ' ]';
    }
    push @$result, $stmt;
  }
  return $result;
}
sub indent_stmts {
  my ($stmts) = @_;
  my $result = '';
  my $indent = '  ';
  foreach my $stmt (@$stmts) {
    $stmt =~ s/\n/"\n" . $indent/eg;
    $result .= $indent . $stmt . ";\n";
  }
  return $result;
}
