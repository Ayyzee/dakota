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

my ($id, $parts);
while (($id, $parts) = each (%$data))
{
    my ($name, $klass_id, $klass_name, $superklass_id, $superklass_name) = &info($data, $id, $parts);
    print "id '$id' is instance-of id '$klass_id'\n";
    if ($name)
    {
	print "\"$name\" is name-of id '$id'\n";
    }
    else
    {
	print "\#\n";
    }
    print "id '$klass_id' is subklass-of id '$superklass_id'\n";
    print "\"$klass_name\" is name-of id '$klass_id'\n";
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
