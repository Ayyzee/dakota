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
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent    = 1;  # default = 2

$main::seq = qr{
                 \[
                 (?:
                   (?> [^\[\]]+ )         # Non-parens without backtracking
                 |
                   (??{ $main::seq }) # Group with matching parens
                 )*
                 \]
             }x;

my $so_ext = 'dylib';

sub unwrap_seq {
  my ($seq) = @_;
  $seq =~ s/\s*\n+\s*/ /gms;
  $seq =~ s/\s+/ /gs;
  return $seq;
}

sub write_data_to_path {
  my ($data, $path) = @_;
  my $str = &Dumper($data);
  $str =~ s/($main::seq)/&unwrap_seq($1)/ges;

  # if (!$path) {
  open PATH, ">$path" or die __FILE__, ":", __LINE__, ": error: \"$path\" $!\n";
  print PATH $str;
  close PATH;
}
my $in_rep_name = $ARGV[0];
my $out_rep_name = $ARGV[1];
my $in_rep =  do $in_rep_name;
my $out_rep = do $out_rep_name;
my $keys_removed = {};

sub trim_tbl_to_permissive {
  my ($tbl, $context, $keys_to_remove) = @_;
  my $deleted_keys = [];
  foreach my $key (keys %$tbl) {
    push @$context, $key;
    if (exists $$keys_to_remove{$key}) {
      push @$deleted_keys, $key;
      my $fq_key = join('.', @$context);
      $$keys_removed{$fq_key} = undef;
    }
    pop @$context;
  }
  map { delete $$tbl{$_}; } @$deleted_keys;

  foreach my $key (keys %$tbl) {
    push @$context, $key;
    if ('HASH' eq ref($$tbl{$key})) {
      &trim_tbl($$tbl{$key}, $context, $keys_to_remove);
    }
    pop @$context;
  }
  return $tbl;
}
my $trim_seqs = [
  [ 'klasses', '*',          'file' ],
  [ 'traits',  '*',          'file' ],
  [ 'klasses', '*', 'slots', 'file' ],
];
sub trim_tbl {
  my ($tbl) = @_;
  foreach my $klass_type ('klasses', 'traits') {
    foreach my $wildcard (keys %{$$tbl{$klass_type}}) {
      if ($$tbl{$klass_type}{$wildcard}{'file'}) {
        delete $$tbl{$klass_type}{$wildcard}{'file'};
        my $fq_key = join('.', ($klass_type, $wildcard, 'file'));
        $$keys_removed{$fq_key} = undef;
      }
      if ($$tbl{$klass_type}{$wildcard}{'slots'} &&
          $$tbl{$klass_type}{$wildcard}{'slots'}{'file'}) {
        delete $$tbl{$klass_type}{$wildcard}{'slots'}{'file'};
        my $fq_key = join('.', ($klass_type, $wildcard, 'slots', 'file'));
        $$keys_removed{$fq_key} = undef;
      }
    }
  }
  return $tbl;
}
my $trim_name;
$in_rep = &trim_tbl($in_rep);
$trim_name = $in_rep_name =~ s/^(.+?)\.(rep)$/$1-trimmed.$2/r;
&write_data_to_path($in_rep, $trim_name);

#print "---\n";

$out_rep = &trim_tbl($out_rep);
$trim_name = $out_rep_name =~ s/^(.+?)\.(rep)$/$1-trimmed.$2/r;
&write_data_to_path($out_rep, $trim_name);

#print STDERR &Dumper(sort keys %$keys_removed);

#map { print $_ . "\n"; } sort keys %$in_rep;
#print "---\n";
#map { print $_ . "\n"; } sort keys %$out_rep;
#map { print $_ . "\n"; } sort keys %{$$in_rep{'keywords'}};
