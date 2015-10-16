#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $have_makefile = [glob("should-pass/pass/*/Makefile")];
my $have_exe =      [glob("should-pass/pass/*/exe")];
my $have_exe_cc =   [glob("should-pass/pass/*/exe-cc")];

my $result = {};

foreach my $path1 (@$have_makefile) {
  if ($path1 =~ m=^(.+?)/Makefile$=) {
   $$result{$1} = 1;
  }
}
foreach my $path2 (@$have_exe, @$have_exe_cc) {
  if ($path2 =~ m=^(.+?)/(exe|exe-cc)$=) {
    delete $$result{$1};
  }
}
foreach my $path (sort keys %$result) {
  print $path . "\n";
}
