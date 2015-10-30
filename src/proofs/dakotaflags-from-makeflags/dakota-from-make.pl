#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

# -D, --directory=
# -I, --include-dir=
# -t, --touch
# -S, --stop, --no-keep-going
# -O, --output-sync[=type] {target,line,recurse,none}

my $dakota_from_make = {
  '--stop'        => '--no-keep-going',
  '--include-dir' => '--include-directory',
};


my $tbl = { '-j' => '--jobs',
            '-k' => '--keep-going' };
my $same_long_opts = [keys %$tbl];
my $result = {};
foreach my $arg (@ARGV) {
  if ($arg =~ m/^(--.+)$/) {
    my $long_opt = $1;
    foreach my $opt (@$same_long_opts) {
      if ($opt eq $long_opt) {
        $$result{$long_opt} = undef;
      }
    }
    # skip for now
  } elsif ($arg =~ m/^-(.+)$/) {
    my $chars = [split(//, $1)];
    foreach my $char (@$chars) {
      if ($$tbl{"-$char"}) {
        $$result{$$tbl{"-$char"}} = undef;
      }
    }
  }
}
my $jobs_value = [
  'MAKE_JOBS_NUM',
  'MAKE_JOBS',
  'JOBS_NUM',
  'JOBS',
  'DAKOTA_JOBS_NUM',
  'DAKOTA_JOBS',
];
foreach my $value (@$jobs_value) {
  if ($ENV{$value}) {
    if ($ENV{$value} =~ m/^\d+$/) {
      $$result{'--jobs'} = $ENV{$value};
      last;
    }
  }
}
use Data::Dumper; print &Dumper($result);
my @opts = keys %$result;
