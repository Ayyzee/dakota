#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent    = 2; # default = 2

undef $/;
my $ops = [];

while (<>)
{
    push @$ops, split /\s/;
}
@$ops = sort @$ops;
my $num_ops = scalar@$ops;
print "  //num_ops = $num_ops\n";
#print STDERR Dumper $ops;

my $tree = {};

my $op;
foreach $op (@$ops)
{
    my $chars = [split //, $op];
    &add_subtbl($tree, $chars);
    #print Dumper $tree;
}
#print STDERR Dumper $tree;
#exit 0;
my $col = 1;
$" = '';
&switch_with_arg($tree, 1, $col, []);

sub add_subtbl
{
    my ($tbl, $chars) = @_;
    if (@$chars)
    {
	my $char = shift @$chars;
	if (@$chars)
	{
	    if (!exists $$tbl{$char})
	    {
		$$tbl{$char} = {};
	    }
	    &add_subtbl($$tbl{$char}, $chars);
	}
	else
	{
	    $$tbl{$char} = {};
	}
    }
}

sub colprint
{
    my ($col_num, $string) = @_;
    my $result_str = '';
    $col_num *= 2;
    $result_str .= ' ' x $col_num;
    $result_str .= $string;
    print $result_str;
}
sub colprintln
{
    my ($col_num, $string) = @_;
    my $line = $string;
    $line .= "\n";
    &colprint($col_num, $line);
}

sub switch_with_arg
{
    my ($tbl, $argnum, $col, $chars) = @_;

    my $c = "c$argnum";

    &colprintln($col, "char_t $c = get_char(file);");
    &colprintln($col, "switch ($c)");
    &colprintln($col, "{");
    $col++;
    
    my $firsts = [sort keys %$tbl]; # order lexically

    my ($first, $rest);
    #while (($first, $rest) = each (%$tbl))
    foreach $first (@$firsts)
    {
	$rest = $$tbl{$first};
	push @$chars, $first;
	&colprintln($col, "case '$first':");
	&colprintln($col, "{");
	$col++;
	if ($rest && keys %$rest)
	{
	    $argnum++;
	    &switch_with_arg($rest, $argnum, $col, $chars); # recursive
	    $argnum--;
	}
	#&colprintln($col, "// '@$chars'");
	&colprintln($col, "return token::make('@$chars', file, line, column);");
	$col--;
	#&colprintln($col, "} // case '$first':");
	&colprintln($col, "}");
	pop @$chars;
    }
    $col--;
    #&colprintln($col, "} // switch ($c)");
    &colprintln($col, "}");
    &colprintln($col, "unget_char(file, $c);");
}
