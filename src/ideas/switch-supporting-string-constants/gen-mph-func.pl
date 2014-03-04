#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent    = 1; # default = 2

my $in_strs = [];

while (<STDIN>) {
    chomp $_;
    push @$in_strs, $_;
}

my $tree = &gen_tree($in_strs);

if (1) {
    open OUT, ">test.pl" or die "$!\n";
    print OUT &Dumper($tree);
    close OUT or die "$!\n";
}

my $name = $ARGV[0];

$" = '';
my $fail = -1;
my $result = &gen_mph($tree, $name);
print $result;

sub gen_mph
{
    my ($tbl, $name) = @_;
    my $i = 0;
    my $result = '';
    my $col = 0;
    &append_col(\$result, $col, "__attribute__((const)) int $name(const char* str)\n");
    &append_col(\$result, $col, "{\n");
    $col++;
    &append_col(\$result, $col, "switch (str[$i]) {\n");
    my $v = 0; # initial/lowest case label value
    my $str;
    &gen_mph_recursive($tbl, $i = 1, \$v, $str = [], \$result, $col + 1);
    &append_col(\$result, $col + 1, "default: return $fail; }\n");
    $col--;
    &append_col(\$result, $col, "}\n");
    return $result;
}
sub gen_mph_recursive
{
    my ($tbl, $i, $v, $str, $result, $col) = @_;
    my $chars = [ sort keys %$tbl ];
    foreach my $char (@$chars) {
	if ("\0" eq $char) {
	    &append_col($result, $col, "case '\\0': return $$v; /*\"@$str\"*/\n");
	    $$v++;
        }
        else {
	    &append_col($result, $col, "case '$char': { switch (str[$i]) {\n");
	    push @$str, $char;
            &gen_mph_recursive($$tbl{$char}, $i + 1, $v, $str, $result, $col + 1);
	    pop @$str;
	    &append_col($result, $col + 1, "default: return $fail; } break; }\n");
        }
    }
}
sub gen_tree
{
    my ($strs) = @_;
    my $result = {};
    $strs = [sort @$strs];
    foreach my $str (@$strs) {
        my $chars = [split //, $str];

	my $current_context = $result;
        foreach my $char (@$chars) {
	    if (!$$current_context{$char}) {
		$$current_context{$char} = {};
	    }
	    $current_context = $$current_context{$char};
	}
	$$current_context{"\0"} = $str;
    }
    $result;
}
sub append_col
{
    my ($result, $col_num, $string) = @_;
    $col_num *= 2;
    my $pad = '';
    $pad .= ' ' x $col_num;
    $$result .= $pad;
    $$result .= $string;
}
