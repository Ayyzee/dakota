#!/usr/bin/perl -w

use strict;
use Cwd;

my $dir = $ARGV[0];
die if 1 != @ARGV;
die if !defined $dir;

chdir $dir;
my $rootdir = getcwd;
print $rootdir;
