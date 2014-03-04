#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

undef $/;

my $str = <STDIN>;
my $seq = &convert($str);
my $sorted_seq = [ sort @$seq ];
print Dumper $sorted_seq;

sub convert
{
    my ($str) = @_;
    my $seq = [];

    while ($str =~ m|^\s+(\w)\s+(\w+).*?$|gm)
    {
        push @$seq, { 'type' => $1, 'symbol' => $2 };
    }
    return $seq;
}
