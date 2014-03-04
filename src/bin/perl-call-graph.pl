#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $asi = qr/::\w+/;    # absolute scoped identifier
my $rsi = qr/\w+$asi*/; # relative scoped identifier

my $exports = {};

undef $/;
my $filestr = <STDIN>;
$filestr =~ s/\#.*?$//gm; # strip comments
if ($filestr =~ m/\@EXPORT\s*=\s*qw\((.*?)\);/gs)
{
    my $export;
    foreach $export (split /\s+/, $1)
    {
        $$exports{$export} = undef;
    }
}

my $edges = {};
my $srcs = {};
my $dsts = {};

my $sbs = [split /sub\s+($rsi)/, $filestr];
shift @$sbs;

my $tbl = {};
my $i;
for ($i = 0; $i < @$sbs; $i += 2)
{
    $$tbl{$$sbs[$i]} = {};
    while ($$sbs[$i + 1] =~ m/\&($rsi)/g)
    {
        $$tbl{$$sbs[$i]}{$1} = undef;
    }
    while ($$sbs[$i + 1] =~ m/(\w+::compare)/g)
    {
        $$tbl{$$sbs[$i]}{$1} = undef;
    }
}

print "digraph dg\n";
print "{\n";

print "  graph [ rankdir = LR ];\n";
print "  graph [ center = true ];\n";
print "  graph [ rotate = 90 ];\n";
print "  graph [ size = \"10,7.5\" ];\n";
print "  graph [ ratio = fill ];\n";
print "  //graph [ ordering = out ];\n";
print "  node [ shape = box ];\n";
print "\n";

my ($sub_name, $sub_block);
while (($sub_name, $sub_block) = each (%$tbl))
{
    $$dsts{$sub_name} = undef;

    my $call_site;
    foreach $call_site (keys %$sub_block)
    {
        $$srcs{$call_site} = undef;
        my $edge = "\"$sub_name\" -> \"$call_site\";";
        if (!exists $$edges{$edge})
        {
            print "  $edge\n";
            $$edges{$edge} = 1;
        }
        else
        {
            $$edges{$edge}++;
        }
    }
}
my ($name, $dummy);

if (1)
{
    while(($name, $dummy) = each(%$dsts))
    {
        delete $$srcs{$name};
    }
    while(($name, $dummy) = each(%$exports))
    {
        delete $$srcs{$name};
    }
    print "\n";
    
    while(($name, $dummy) = each(%$srcs))
    {
        print "  $name [ color = grey, fontcolor = grey ];\n";
    }
    while(($name, $dummy) = each(%$exports))
    {
        print "  $name [ style = dashed ];\n";
    }
    print "}\n";
}
else
{
    # dump destinations without sources
    # possible dead code

    delete $$dsts{'start'};

    while(($name, $dummy) = each(%$srcs))
    {
        delete $$dsts{$name};
    }
    while(($name, $dummy) = each(%$exports))
    {
        delete $$dsts{$name};
    }
    print STDERR Dumper $dsts;
}

#print Dumper $edges;
