#!/usr/bin/perl -w

use strict;

undef $/;
my $instr = <STDIN>;
my $in = eval "[ $instr ]";

print "digraph {\n";
print "  graph [ rankdir = \"TB\" ];\n";
print "  node [ shape = plaintext ];\n";
foreach my $tbl (@$in)
{
    my ($outfile, $infiles);
    
    while (($outfile, $infiles) = each (%$tbl))
    {
	foreach my $infile (@$infiles)
	{
	    print "  \"$infile\" -> \"$outfile\";\n";
	}
    }
}
print "}\n";
