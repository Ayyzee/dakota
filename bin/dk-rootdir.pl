#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use Cwd;

my $dir = $ARGV[0];
die if 1 != @ARGV;
die if !defined $dir;

chdir $dir;
my $rootdir = getcwd;
print $rootdir;
