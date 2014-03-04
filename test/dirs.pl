#!/usr/bin/perl -w

use strict;

foreach my $exe_path (@ARGV)
{
    $exe_path =~ s|/[^/]+$||;
    print "$exe_path\n";
}
