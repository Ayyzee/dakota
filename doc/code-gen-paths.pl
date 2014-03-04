#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $tbl = {};

while (<>)
{
    if (m/(.+?)\s*:\s+(.*?)$/)
    {
        my $lhs = $1;
        my $rhs = $2;

	$lhs =~ s/([a-z-]+)\|/$1\\l/g;
	if ($lhs =~ m/\\l/g)
	{
	    $lhs .= "\\l";
	}

        if (!$$tbl{$lhs})
        { $$tbl{$lhs} = {}; }
        my $part;
        foreach $part (split /\s+/, $rhs)
        {
	    if ($part =~ m/\|/g)
	    {
		my $opts = [split /\|/, $part];
		$part = '';
		my $opt;
		foreach $opt (@$opts)
		{
		    $part .= "$opt\\l";
		}
	    }

            $$tbl{$lhs}{$part} = undef;
        }
    }
}
#print STDERR Dumper $tbl;

print "digraph \"code-gen-paths\" { graph [ rankdir = LR, page = \"8.5,11\", size = \"7.5,10\", center = true ]; node [ shape = plaintext ];\n";
my ($nodes_tbl, $edges_tbl) = &dump_edges(undef, $tbl);
my $edges = [sort keys %$edges_tbl];
print "@$edges\n";
my $nodes = [sort keys %$nodes_tbl];
print "@$nodes";
print "}\n";

my $_nodes = {};
my $_edges = {};
sub dump_edges
{
    my ($lhs, $scope) = @_;
    if ($lhs)
    {
	my $label;
	if ($lhs =~ m/\\l/g)
	{
	    $label = $lhs;
	    $label =~ s/([a-z]+-)+([a-z]+)(\\l)/$2$3/g;
	    $$_nodes{"  \"$lhs\" [ label = \"$label\" ];\n"} = undef;
	}
        elsif ($lhs =~ m|-([^-]+)$|)
        {
	    $label = $1;
	    $$_nodes{"  \"$lhs\" [ label = \"$label\" ];\n"} = undef;
        }
    }
    if ($scope)
    {
        my ($key, $val);
        while (($key, $val) = each (%$scope))
        {
            if ($lhs)
            {
                $$_edges{"  \"$lhs\" -> \"$key\";\n"} = undef;
            }
            &dump_edges($key, $val);
        }
    }
    return ($_nodes, $_edges);
}
