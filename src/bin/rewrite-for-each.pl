#!/usr/bin/perl -w

use strict;
use warnings;

my $k = qr/[_A-Za-z0-9-]+/; # dakota identifier

undef $/;

if (1)
{
    my $str = <STDIN>;
    $str = &convert($str);
    print $str;
}
else
{
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
}

sub convert
{
    my ($str) = @_;
    $str =~ s|(for\s*\(\s*object-t\s+($k))\s*\:\s*($k)\s*\)|$1, _iterator_ = dk:forward-iterator($3); nullptr != ($2 = dk:next-element(_iterator_); )|gs;
    return $str;
}
