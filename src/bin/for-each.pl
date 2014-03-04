#!/usr/bin/perl -w

use strict;
use warnings;

my $k = qr/[_A-Za-z0-9-]/; # dakota identifier

undef $/;

my $arg;
foreach $arg (@ARGV)
{
    open FILE, "<$arg" or die "$!\n";
    my $str = <FILE>;
    close FILE;
    $str = &convert($str);
    open FILE, ">$arg" or die "$!\n";
    print FILE "$str";
}

sub convert
{
    my ($str) = @_;
    $str =~ s|for\s*\(\s*object-t\s+($k+)\s*=\s*dk:forward-iterator\(($k+)\)\s*;\s*dk:has-element\(\1\)\s*;\s*dk:next-element\(\1\)\s*\)(\s*\{)\s*object-t\s+($k+)\s*=\s*dk:get-element\(\1\)\s*;\n*|for \(object-t $4 \: $2\)$3\n|gs;
    return $str;
}
