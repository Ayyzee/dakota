#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent    = 1; # default = 2

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts = {};

&GetOptions($opts,
            'dot=s',
            'txt=s',
            );

my $states_tbl = do $ARGV[0];

my $doublecircle =
{
    'type' => 1,
    '999' => 1,
};

my $blue =
{
    'qual-type-ident' => 1,
    'qual-scope' => 1,
    'ptr' => 1,
    'type' => 1,
};

open DOT, ">$$opts{'dot'}" or die $?;
my $dot_tbl = &gen_dot($states_tbl, 'type', {});
#print &Dumper($dot_tbl);
my $vals = [values %$dot_tbl];
print DOT "digraph {\n";
print DOT "  graph [ rankdir = LR, center = true, margin = \"0.25\" ];\n";
print DOT "  graph [ page = \"8.5,11\", size = \"7.5,10\" ];\n";
print DOT "  node [ shape = circle ];\n";
foreach my $node (sort keys %$doublecircle) {
    print DOT "  \"$node\" [ shape = doublecircle ];\n";
}
foreach my $node (sort keys %$blue) {
    #print DOT "  \"$node\" [ fontcolor = blue ];\n";
}
print DOT "  //node [ label = \"\" ];\n";

foreach my $val (@$vals) {
    print DOT "  $$val[0] -> $$val[1] [";
    my $delim = '';
    while (my ($key, $val) = each (%{$$val[2]})) {
	print DOT "$delim $key = \"$val\"";
	$delim = ',';
    }
    print DOT " ];\n";
}
print DOT "}\n";
close DOT;
open TXT, ">$$opts{'txt'}" or die $?;
&gen_src($states_tbl, 'type', []);
close TXT;

sub gen_dot
{
    my ($states_tbl, $state1, $result) = @_;
    my $tbl = $$states_tbl{$state1};
    while (my ($token, $states) = each %$tbl) {
	foreach my $state2 (@$states) {
	    if (exists $$states_tbl{$state2}) {
		my $sub_tbl = $$states_tbl{$state2};
		if (keys %$sub_tbl) {
		    if ($state1 ne $state2) {
			&gen_dot($states_tbl, $state2, $result);
		    }
		}
		my $attrs = { 'label' => $token };
		if (exists $$blue{$token}) {
		    $$attrs{'fontcolor'} = 'blue';
		}
		$$result{"$state1 $state2 $token"} = [ $state1, $state2, $attrs ];
	    }
	    else {
		print STDERR "missing state $state2\n";
	    }
	}
    }
    return $result;
}
sub gen_src
{
    my ($states_tbl, $state1, $current_tokens) = @_;
    my $tbl = $$states_tbl{$state1};
    my $tokens = [keys %$tbl];
    foreach my $token (sort @$tokens) {
	my $states = $$tbl{$token};
	foreach my $state2 (sort @$states) {
	    if (exists $$states_tbl{$state2}) {
		my $sub_tbl = $$states_tbl{$state2};
		push @$current_tokens, $token;
		if (keys %$sub_tbl) {
		    &gen_src($states_tbl, $state2, $current_tokens);
		}
		else {
		    print TXT "@$current_tokens\n";
		}
		pop @$current_tokens;
	    }
	    else {
		print TXT "missing state $state2\n";
	    }
	}
    }
}
