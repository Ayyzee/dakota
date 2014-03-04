#!/usr/bin/perl -w

use strict;

my $words = {};

while (<>) {
    while (m/(\w+_t)/g) {
	my $word = $1;
	if ($word !~ m/__/g) {
	    $$words{$word} = 1;
	}
    }
}
map { print "$_\n"; } sort keys %$words;
