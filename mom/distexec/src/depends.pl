#!/usr/bin/perl -w

use strict;
use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $cmd = "g++ -MM";

my $root = &make_depends_graph(\@ARGV);
#print Dumper $root;
&dump_dot($root);

sub make_depends_graph
{
    my ($files) = @_;
    my $root = {};
    my $file;
    foreach $file (@$files)
    {
        my $result = '';
        $result .= `$cmd $file`;
        $result =~ s|(.*?).o:\s*\1.(\w)|$1.$2|gm;
        $result =~ s|\s+\\\n\s+| |gm;
        
        my $parts = [split /\s+/, $result];
        my $target = shift(@$parts);
        
        if (exists $$root{$target}){ die; }
        
        $$root{$target} = $parts;
    }
    return $root;
}

sub dump_dot
{
    my ($root) = @_;
    print "digraph dg\n";
    print "{\n";
    print "  graph \[ page = \"8.5,11\", size = \"7.5,10\" \];\n";
    #print "  graph \[ page = \"11,8.5\", size = \"10,7.5\" \];\n";
    #print "  graph \[ page = \"11,17\", size = \"10,16\" \];\n";
    #print "  graph \[ page = \"17,11\", size = \"16,10\" \];\n";
    print "  graph \[ ratio = fill \];\n";
    print "  graph \[ concentrate = true \];\n";
    #print "  node \[ shape = rect \];\n";
    print "\n";
    my ($target, $depends);
    while (($target, $depends) = each(%$root))
    {
        my $depend;
        foreach $depend (@$depends)
        {
            if ($target eq $depend)
            {
                print "  \"$target\" -> \"$depend\";  \"$target\" \[ color = red \];\n";
                print STDERR "warning: \"$target\" -> \"$depend\";  \"$target\" \[ color = red \];\n";
            }
            else
            {
                print "  \"$target\" -> \"$depend\";\n";
            }
        }
    }
    print "}\n";
}
