#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

undef $/;

my $filestr = <STDIN>;

#   namespace  va { GENERIC
#   =>
#   namespace $va { GENERIC
#
# namespace dk { <type>  <name>(object_t|super_t
# =>
# namespace dk { <type> $<name>(object_t|super_t
#
#   GENERIC <type>  <name>(
#   =>
#   GENERIC <type> $<name>(
#
# dk::<name>
# =>
# dk::$<name>
#
# dk::va::<name>
# =>
# dk::$va::<name>

$filestr =~ s/^(\s*namespace\s*)(va\s*\{\s*VA-GENERIC)/$1\$$2/gms;
$filestr =~ s/^(\s*namespace\s*dk\*\{\s*GENERIC\s+.+?\s*)(\w+\((object_t|super_t))/$1\$$2/gms;
$filestr =~ s/^(\s*GENERIC\s+.+?\s*)(\w+\()/$1\$$2/gms;
$filestr =~ s/(dk::)(\w+)/$1\$$2/gms;
$filestr =~ s/(dk::)(va::\w+)/$1\$$2/gms;

print $filestr;
