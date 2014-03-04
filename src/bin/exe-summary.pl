#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

undef $/;

my $str = <STDIN>;
my $root = eval $str;
#print &Dumper($root);
my $tbl = &convert($root);
#print &Dumper($tbl);
my $result = {};

$$result{'klasses'} =        scalar(keys %{$$tbl{'klasses'}});
$$result{'traits'} =         scalar(keys %{$$tbl{'traits'}});
$$result{'methods'} =        scalar(keys %{$$tbl{'methods'}});
$$result{'selectors'} =      scalar(keys %{$$tbl{'selectors'}});
$$result{'selectors-mono'} = scalar(keys %{$$tbl{'selectors-mono'}});
$$result{'selectors-poly'} = $$result{'selectors'} - $$result{'selectors-mono'};

print &Dumper($result);

sub convert
{
    my ($root) = @_;
    my $tbl = { 'klasses' => {}, 'traits' => {}, 'selectors' => {}, 'methods' => {} };

    my ($kname, $kinfo);
    while (($kname, $kinfo) = each(%$root))
    {
	my $ktype = $$kinfo{'type'};

	if ('klass' eq $ktype)
	{ $$tbl{'klasses'}{$kname} = 1; }
	elsif ('trait' eq $ktype)
	{ $$tbl{'traits'}{$kname} = 1; }
	else
	{ die; }

	my ($mname, $minfo);
	while (($mname, $minfo) = each (%{$$kinfo{'methods'}}))
	{
	    if (!$$tbl{'selectors'}{$mname})
	    { $$tbl{'selectors'}{$mname} = []; }
	    push @{$$tbl{'selectors'}{$mname}}, $kname;
	}
	while (($mname, $minfo) = each (%{$$kinfo{'methods'}}))
	{
	    if ($$minfo{'defined?'})
	    {
		my $name = "$kname:$mname";
		if (!$$tbl{'methods'}{$name})
		{ $$tbl{'methods'}{$name} = 1; }
	    }
	}
    }
    $$tbl{'selectors-mono'} = {};

    my ($mname, $minfo);
    while (($mname, $minfo) = each (%{$$tbl{'selectors'}}))
    {
	if (1 == @$minfo)
	{
	    $$tbl{'selectors-mono'}{$mname} = $$minfo[0];
	}
    }
    return $tbl;
}
