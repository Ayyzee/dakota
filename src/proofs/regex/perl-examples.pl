#!/usr/bin/perl -w

use strict;
use warnings;

my $str = "this is a thing";
print "$str\n";
$str =~ s/\bthing\b/big thing/;
print "$str\n";
if ($str !~ s/\bis\b/is not/) {
} else {
}
print "$str\n";
my $count = $str =~ s/s/S/g;
print "$str\n";
print "count=$count\n";
