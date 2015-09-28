#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 0;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

my $macros = do $ARGV[0];;
my $macros_str = &Dumper($macros);

$macros_str =~ s/','/'--comma--'/g; # encode

$macros_str =~ s/',\s*'/', '/g;
$macros_str =~ s/\[\s*'/\[ '/g;
$macros_str =~ s/',?\s*\]/' \]/g;

$macros_str =~ s/'--comma--'/','/g; # decode
print $macros_str;
