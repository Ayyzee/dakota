#!/usr/bin/perl -w

use strict;

undef $/;

my $arg;
foreach $arg (@ARGV)
{
    open FILE, "<$arg" or die "$!\n";
    my $filestr = <FILE>;
    close FILE;
    
    my $basearg = $arg;
    $basearg =~ s|\.dot$||g;
    $filestr =~ s|(digraph\s+).*?\{\s*graph|$1\"$basearg\"\n\{\n  label = \"$basearg\";\n  graph|s;
#    print "$filestr\n";

    open FILE, ">$arg" or die "$!\n";
    print FILE $filestr;
    close FILE;
}
