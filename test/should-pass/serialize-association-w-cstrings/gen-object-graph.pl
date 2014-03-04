#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $data = do $ARGV[0];

#print Dumper $data;

my $exprs = {};

print "digraph dg\n{\n";
print "  node [ shape = rect, style = rounded ];\n";

my ($id, $parts);
while (($id, $parts) = each (%$data))
{

    if (0)
    {
	my $part;
	foreach $part (@$parts)
	{
	    my ($lhs, $rhs);
	    while (($lhs, $rhs) = each (%$part))
	    {
		if ('HASH' eq ref $rhs)
		{
		    if (exists $$rhs{'idref'})
		    {
			if ('superklass' eq $lhs)
			{
			    ##&print_once("$id -> $$rhs{'idref'};");
			}
			elsif ('klass' eq $lhs)
			{
			    ##&print_once("$id -> $$rhs{'idref'} [ style = dashed ];");
			}
			else
			{
			    &print_once("$$rhs{'idref'} -> $id [ dir = back, style = dotted ];");
			}
		    }
		}
	    }
	}
    }

    my ($name, $klass_id, $klass_name, $superklass_id, $superklass_name) = &info($data, $id, $parts);

    if (0)
    {
	if ($name)
	{
	    &print_once("_$id [ label = \"$id : $name\" ];");
	}
	else
	{
	    &print_once("_$id [ label = \"$id\" ];");
	}
	&print_once("_$klass_id -> _$id [ dir = back, style = dashed ];");
    }
    if (1)
    {
	if ($name)
	{
	    &print_once("__$id [ label = \"$id : $name\" ];");
	}
	else
	{
	    &print_once("__$id [ label = \"$id\" ];");
	}
	&print_once("__$superklass_id -> __$klass_id [ dir = back ];");
	&print_once("__$klass_id [ label = \"$klass_id : $klass_name\" ];");
    }
}

print "}\n";

sub print_once
{
    my ($expr) = @_;

    if (!exists $$exprs{$expr})
    {
	print "  $expr\n";
	$$exprs{$expr} = undef;
    }
}

sub info
{
    my ($root, $id, $parts) = @_;

    my $name = undef;
    if (exists $$root{$id}[1]{'name'})
    {
	$name = $$root{$id}[1]{'name'};
    }

    # 'object' is always part 0
    my $klass_id = $$parts[0]{'klass'}{'idref'};

    # 'abstract-klass' is always part 1
    my $klass_name = $$root{$klass_id}[1]{'name'};
    my $superklass_id = $$root{$klass_id}[1]{'superklass'}{'idref'};
    my $superklass_name = $$root{$superklass_id}[1]{'name'};

    return ($name, $klass_id, $klass_name, $superklass_id, $superklass_name);
}
