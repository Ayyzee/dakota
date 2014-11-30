#!/usr/bin/perl -w

use strict;

my $dir = $ENV{'DKT_DIR'};
die if !$dir;

while (<>)
{
    if ($_ =~ m/^(.*?):/)
    {
	my $path = $1;

	# if its a valid relative path
	if (!($path =~ m|^/|))
	{
	    if (-e $path)
	    {
		print "$dir";
	    }
	}
    }
    print $_;
}
