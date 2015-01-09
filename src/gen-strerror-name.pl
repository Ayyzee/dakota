#!/usr/bin/perl -w

use strict;

my $err_set = {};

while (<>)
{
    if (m/\#\s*define\s+(E[A-Z0-9]+)\s+(E[A-Z0-9]+|\d+)/)
    {
	my $err = $1;
	my $val = $2;
	$$err_set{$err} = undef;
    }
}

my $key;
foreach $key (keys %$err_set)
{
    print "\#if defined $key\n";
    print "  set_name($key, \"$key\");\n";
    print "\#endif\n";
}
