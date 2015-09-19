#!/usr/bin/perl -w

use strict;
use Data::Dumper;

undef $/;
my $instr = <STDIN>;
my $in = eval $instr;
print Dumper $in;
