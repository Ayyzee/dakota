#!/usr/bin/perl -w

use strict;
use warnings;

undef $/;
my $str = <STDIN>;

$str =~ s|char-t\s+const\s*\*|const char-t *|g;
print "$str\n";
