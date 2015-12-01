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
$main::block_in = qr{
                      (?:
                        (?> [^{}]+ )         # Non-braces without backtracking
                      |
                        (??{ $main::block }) # Group with matching braces
                      )*
                  }x;
my $implicit_metaklass_stmts = qr/( *klass\s+(((klass|trait|superklass)\s+[\w:-]+)|(slots|method)).*)/s;
undef $/;
while (<>) {
  while ($_ =~ m/^klass(\s+)([\w:-]+)(\s*)\{(\s*$main::block_in\s*)\}/gms) {
    my ($s1, $klass_name, $s2, $body) = ($1, $2, $3, $4);
    $body =~ s/$implicit_metaklass_stmts/&metaklass_body_rewrite($klass_name, $1)/egs;
    my $klass_metaklass_defn = "klass$s1$klass_name$s2\{ klass $klass_name-klass;" . $body . "}";
    $klass_metaklass_defn = &compress_lines($klass_metaklass_defn, 1);
    print $klass_metaklass_defn . "\n";
  }
}
sub compress_lines {
  my ($lines, $num) = @_;
  # ignoring $num presently
  $lines =~ s/ *}\s*}(\s*)$/} }$1/;
  return $lines;
}
sub metaklass_body_rewrite {
  my ($klass_name, $body) = @_;
  $body =~ s/klass\s+(superklass\s+[\w:-]+)/$1/x;
  $body =~ s/klass\s+(klass     \s+[\w:-]+)/$1/x;
  $body =~ s/klass\s+(trait     \s+[\w:-]+)/$1/x;
  $body =~ s/klass\s+(slots)/$1/;
  $body =~ s/klass\s+(method)/$1/;
  my $result = "} klass $klass_name-klass {\n" . $body;
  return $result;
}
