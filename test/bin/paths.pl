#!/usr/bin/perl
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

use File::Spec;

my $pairs = [
  [ "/robert/dakota/test", "/robert/dakota/test/should-pass/add-method-to-klass" ],
  [ "/robert/dakota/src", "/robert/dakota-obj" ],
];
my $sep = '';

foreach my $pair (@$pairs) {
  my $wd1 = $$pair[0];
  my $wd2 = $$pair[1];
  my $rel = File::Spec->abs2rel($wd2,  $wd1);
  print $sep;
  print "wd1=$wd1\n" . "wd2=$wd2\n" . "rel=$rel\n";
  $sep = "\n";
}
