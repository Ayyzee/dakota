#!/usr/bin/perl -w

use strict;
use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $edges = {};

while (<>)
{
    if (/(.*?)\:\#include\s+"(.*?)"/)
    {
        $$edges{$1}{$2} = 1;
    }
    elsif (/(.*?)\:\#include\s+<(.*?)>/)
    {
    }
    else
    {
        print STDERR "ERROR: malformed input \"$_\"\n";
        die;
    }
}

print "digraph dg\n";
print "{\n";
print "  graph \[ page = \"8.5,11\", size = \"7.5,10\" \];\n";
#print "  graph \[ page = \"11,8.5\", size = \"10,7.5\" \];\n";
#print "  graph \[ page = \"11,17\", size = \"10,16\" \];\n";
#print "  graph \[ page = \"17,11\", size = \"16,10\" \];\n";
print "  graph \[ ratio = fill \];\n";
#print "  graph \[ concentrate = true \];\n";
print "  node \[ shape = rect \];\n";
print "\n";

my ($lhs, $tbl);
while (($lhs, $tbl) = each (%$edges))
{
    my ($rhs, $dummy);
    while (($rhs, $dummy) = each (%$tbl))
    {
        print "  \"$lhs\" -> \"$rhs\";\n";
    }
}

print "}\n";

#print Dumper $edges;
