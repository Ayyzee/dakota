#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $nl = "\n";
undef $/;
my $d = '';
print 'digraph {' . $nl;
while (<>) {
  my $filestr = $_;
  $filestr =~ s/\n*digraph\s*\{\n+/$d/;
  $filestr =~ s/\n*\}\n+/\n/s;
  print $filestr;
  $d = $nl;
}
print '}' . $nl;
