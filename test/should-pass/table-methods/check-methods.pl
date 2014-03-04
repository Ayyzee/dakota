#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse =    1;
$Data::Dumper::Sortkeys = 1;

undef $/;

my $instr = <STDIN>;
my $in = eval $instr;

my ($key, $val);
while (($key, $val) = each (%$in))
{
    if ($val)
    {
        $val =~ s|_|-|g;
        $val =~ s|object\:\:slots-t\*|object-t|g;
        $val =~ s|, |,|g;
        $$in{$key} = $val;
    }
}

print Dumper $in;
