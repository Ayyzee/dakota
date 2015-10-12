#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $tbl = {};

while (<>) {
  while (m/dk(_|-)intern\s*\(\s*(".*?")\s*\)/g) {
    my $str = $2;
    &add_str($tbl, $str);
  }
}
my $num = scalar keys %$tbl;
print $num . "\n";

use Data::Dumper; print &Dumper($tbl);

sub add_str {
  my ($tbl, $str) = @_;
  if (!$$tbl{$str}) {
    $$tbl{$str} = 0;
  }
  $$tbl{$str}++;
}
