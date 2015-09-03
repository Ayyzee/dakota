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
$Data::Dumper::Purity    = 1;
$Data::Dumper::Sortkeys  = \&order_keys;
$Data::Dumper::Indent    = 2;   # default = 2

sub order_keys {
  my ($tbl) = @_;
  my $result = [];
  my $result_canon = [ '-type', '-name', 'graph', 'edge', 'node', '-stmts' ]; # must have '-stmts'
  if ($$tbl{'-stmts'}) {
    foreach my $key (@$result_canon) {
      if ($$tbl{$key}) {
        push @$result, $key;
      }
    }
  } else {
    $result = [sort keys %$tbl]
  }
  return $result;
}

undef $/;

my $ENCODED_STRING_BEGIN = '__ENCODED_STRING_BEGIN__';
my $ENCODED_STRING_END =   '__ENCODED_STRING_END__';

sub decode_str {
  my ($str) = @_;
  $str =~ s{$ENCODED_STRING_BEGIN([0-9A-Fa-f]*)$ENCODED_STRING_END}{pack('H*', $1)}gseo;
  return $str;
}
sub decode_strs {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s{$ENCODED_STRING_BEGIN([0-9A-Fa-f]*)$ENCODED_STRING_END}{pack('H*', $1)}gseo;
}
sub encode_str {
  my ($str) = @_;
  $str =~ s/^"(.*)"$/$1/;
  return $ENCODED_STRING_BEGIN . unpack('H*', $str) . $ENCODED_STRING_END;
}
sub encode_strs {
  my ($filestr_ref) = @_;
  # not-escaped " .*? not-escaped "
  my $regex = qr/(?<!\\)".*?(?<!\\)"/;
  $$filestr_ref =~ s{($regex)}{&encode_str($1)}gseo;
}
sub newlines {
  my ($str) = @_;
  $str =~ s|[^\n]+||gs;
  return $str;
}

foreach my $arg (@ARGV) {
  open(my $f, "<", $arg) || die "$!";
  my $filestr = <$f>;
  close($f);

  $filestr =~ s=(//.*?\n|/\*.*?\*/)=newlines($1)=egs;
  &encode_strs(\$filestr);

  my $result = { '-stmts' => [] };

  if ($filestr =~ m/^\s*(digraph|graph)\s*(\w*)\s*\{\s*(.*?)\s*\}\s*;*\s*$/s) {
    $$result{'-type'} = $1;
    if ($2) {
      $$result{'-name'} = &decode_str($2);
    }
    my $body = $3;

    my $stmts = [split(/\s*;\s*/, $body)];
    foreach my $stmt (@$stmts) {
      if ($stmt =~ m/^\s*(.+?)\s*(\[\s*(.+?)\s*\])?\s*$/s) {
        my ($nodes_str, $pairs_str) = ($1, $3);
        my $nodes = [split(/\s*--\s*|\s*->\s*/, $nodes_str)];
        $nodes = [map { &decode_str($_) } @$nodes];
        my $attrs = {};
        my $pairs;
        if ($pairs_str) {
          $pairs = [split(/\s*,\s*/, $pairs_str)];
          foreach my $pair (@$pairs) {
            if ($pair =~ m/^\s*(.+?)\s*=\s*(.+?)\s*$/s) {
              my ($attr, $value) = ($1, $2);
              $$attrs{$attr} = &decode_str($value);
            } else { die $arg . ": $pair\n"; }
          }
        }
        my $special_nodes = { 'graph' => 1, 'edge' => 1, 'node' => 1 }; # don't handle subgraph yet!!!
        if (1 == scalar @$nodes && $$special_nodes{$$nodes[0]}) {
          $$result{$$nodes[0]} = $attrs;
        } else {
          push @{$$result{'-stmts'}}, [$nodes, $attrs];
        }

      } else { die $arg . ": $stmt\n"; }
    }
  } else { die $arg . ": <filestr>\n"; }

  my $outstr = &Dumper($result);
  $outstr =~ s/(\[\s*.*?\s*\])/&single_line($1)/egs;
  $outstr =~ s/\{\s+/\{ /gs;

  if (0) {
    print $outstr;
  }
  else {
    open($f, ">", $arg . '.pl');
    print $f $outstr;
    close($f);
  }
}
sub single_line {
  my ($buf) = @_;
  $buf =~ s/\s+/ /gs;
  return $buf;
}
