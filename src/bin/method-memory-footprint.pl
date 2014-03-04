#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $args;

if (0 == @ARGV)
{
    undef $/;
    my $args_str = <STDIN>;
    $args = eval $args_str;
}
else
{
    $args = {};
    &GetOptions($args,
		'klasses=s',
		'selectors=s',
		'methods=s',
		);
}
#print &Dumper($args);
    
my $num_klasses = $$args{'klasses'};
my $num_selectors = $$args{'selectors'};
my $num_methods = $$args{'methods'};
my $exp;
my $num_bytes;
my $num_k_bytes;
my $rt = [];

print "(num-klasses * num-selectors * sizeof(method-t))\n";
$num_bytes = $num_klasses * $num_selectors * 4;
$$rt[0] = $num_bytes;
$num_k_bytes = sprintf("%.1f", $num_bytes / 1024);
print "($num_klasses * $num_selectors * 4) = ${num_k_bytes}k\n\n";

print "\# num-selectors < 16k\n";
print "(num-klasses * num-selectors * sizeof(uint16-t)) + (num-methods * sizeof(method-t))\n";
$num_bytes = ($num_klasses * $num_selectors * 2) + ($num_methods * 4);
$$rt[1] = $num_bytes;
$num_k_bytes = sprintf("%.1f", $num_bytes / 1024);
print "($num_klasses * $num_selectors * 2) + ($num_methods * 4) = ${num_k_bytes}k\n";

print "\# num-selectors < 256\n";
print "(num-klasses * num-selectors * sizeof(uint8-t )) + (num-methods * sizeof(method-t))\n";
$num_bytes = ($num_klasses * $num_selectors * 1) + ($num_methods * 4);
$$rt[2] = $num_bytes;
$num_k_bytes = sprintf("%.1f", $num_bytes / 1024);
print "($num_klasses * $num_selectors * 1) + ($num_methods * 4) = ${num_k_bytes}k\n\n";
