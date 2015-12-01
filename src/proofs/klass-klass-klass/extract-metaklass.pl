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
sub metaklass_body_rewrite {
  my ($klass_name, $metaklass_stmts) = @_;
  $metaklass_stmts =~ s/klass\s+(superklass\s+[\w:-]+)/$1/x;
  $metaklass_stmts =~ s/klass\s+(klass     \s+[\w:-]+)/$1/x;
  $metaklass_stmts =~ s/klass\s+(trait     \s+[\w:-]+)/$1/x;
  $metaklass_stmts =~ s/klass\s+(slots)/$1/;
  $metaklass_stmts =~ s/klass\s+(method)/$1/;
  my $result = "} klass $klass_name-klass {\n" . $metaklass_stmts;
  return $result;
}
sub klass_with_implicit_metaklass_rewrite {
  my ($s1, $klass_name, $s2, $body) = @_;
  my $result;
  if ($body =~ s/$implicit_metaklass_stmts/&metaklass_body_rewrite($klass_name, $1)/egs) {
    $result = "klass$s1$klass_name$s2\{ klass $klass_name-klass;" . $body . "}";
  } else {
    $result =  "klass$s1$klass_name$s2\{" . $body . "}";
  }
  $result = &compress_lines($result, 1);
  return $result;
}
sub compress_lines {
  my ($lines, $num) = @_;
  # ignoring $num presently
  $lines =~ s/ *}\s*}(\s*)$/} }$1/;
  return $lines;
}
sub rewrite_klass_defn_with_implicit_metaklass_defn {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/^klass(\s+)([\w:-]+)(\s*)\{(\s*$main::block_in\s*)\}/&klass_with_implicit_metaklass_rewrite($1, $2, $3, $4)/egms;
}
undef $/;
while (<>) {
  my $filestr = $_;
  &rewrite_klass_defn_with_implicit_metaklass_defn(\$filestr);
  print $filestr;
}
