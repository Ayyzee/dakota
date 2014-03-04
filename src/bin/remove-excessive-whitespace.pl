#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $str = 'const char * ( * ) ( const char * , const char * )';

print "$str\n";
$str =~ s|(\w)\s+(\w)|$1__WHITESPACE__$2|g;
$str =~ s|\s+||g;
$str =~ s|__WHITESPACE__| |g;
#$str =~ s|(?!<\w)\s+(?!=\w)||g;
print "$str\n";
