#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

use strict;
use warnings;

my $words = {};
my $lc_alphabet = 'abcdefghijklmnopqrstuvwxyz';
die if 26 != length $lc_alphabet;
my $last_char_tbl = {};

foreach my $char (split(//, $lc_alphabet)) {
  $$last_char_tbl{$char} = {};
}
#print &Dumper($last_char_tbl);
my $words_file = "/usr/share/dict/words";

my $fh;
open($fh, "<", $words_file)
  or die "cannot open > $words_file: $!";

while (<$fh>) {
  chomp $_;
  my $word = lc($_);
  $word =~ m/^\s*(.*)(.)\s*$/;
  my $base = $1;
  my $last_char = $2;
  $$words{$word} = [ $base, $last_char ];
 #print $word . " " . &Dumper($$words{$word}) , "\n";

  if (!exists $$last_char_tbl{$last_char}) {
    print STDERR "warning: not in range a-z : $last_char\n";
  } else {
    $$last_char_tbl{$last_char}{$word} = 1;
  }
}
close ($fh) or warn "could not close file handle to $words_file: $!";

#print &Dumper($last_char_tbl);

map { printf "% 6i  %s  %.4f%%\n",
        scalar keys %{$$last_char_tbl{$_}},
        $_,
        (scalar keys %{$$last_char_tbl{$_}}) / (scalar keys %$words) * 100; } keys %$last_char_tbl;

#print &Dumper($$last_char_tbl{'p'});
#print &Dumper($$last_char_tbl{'x'});
