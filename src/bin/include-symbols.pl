#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2
$Data::Dumper::Sortkeys  = 1;

undef $/;

my $root = { 'file-to-type' => {}, 'type-to-file' => {} };
my $exclude_types =
{
    'uint-t' => 1,
    'int-t' => 1,
    'char' => 1,
    'unsigned char' => 1,
    'signed char' => 1
};

foreach my $arg (@ARGV)
{
    my $in = open IN, "<$arg" or die "$arg: $!\n";
    my $instr = <IN>;
    close IN;

    while ($instr =~ m/export\s*(<.*?>).*?export\s+slots\s+(.+?)\s*;/gs)
    {
	my ($file, $type) = ($1, $2);
	if (!$$exclude_types{$type} &&
	    !($type =~ m/\(\*\)/))
	{
	    $$root{'file-to-types'}{$file}{$type} = 1;
	    $$root{'type-to-file'}{$type} = $file;

	    if ($type =~ m/^(struct|union|enum)\s+(.+)$/)
	    {
		my $alias = $2;
		
		$$root{'file-to-types'}{$file}{$alias} = 1;
		$$root{'type-to-file'}{$alias} = $file;
	    }

	    #printf "from %-14s import %s;\n", $file, $type;
	}
    }
}
if (1) {
    print &Dumper($$root{'type-to-file'});
}
if (1) {
    my $files = [sort keys %{$$root{'file-to-types'}}];
    my $max_width = 0;
    foreach my $file (@$files)
    {
	my $width = length $file;
	if ($max_width < $width)
	{ $max_width = $width; }
    }
    foreach my $file (@$files)
    {
	my $types = $$root{'file-to-types'}{$file};
	my $width = length $file;
	my $head = "from $file ";# import";
	$head .= ' ' x ($max_width - $width);
	$head .= "export";
	print $head;
	my $len = length $head;
	my $delim = '';
	foreach my $type (sort keys %$types)
	{
	    print "$delim";
	    if ('' ne $delim)
	    {
		print "\n", ' ' x $len;
	    }
	    print " $type";
	    $delim = ',';
	}
	print ";\n";
    }
}
