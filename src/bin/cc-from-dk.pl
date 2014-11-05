#!/usr/bin/perl -w

# prefix = /usr/local
BEGIN { unshift @INC, (exists $ENV{'DK_NO_PREFIX'} ? "bin" : "/usr/local/bin") };

use strict;
use warnings;

use dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

sub main
{
    undef $/;
    my $filestr = <STDIN>;
    my $ka_generics = &ka_generics();
    my $name;
    &convert_dk_to_cxx(\$filestr, $ka_generics, $name = undef);
    print $filestr;
    return 0;
}

sub convert_dk_to_cxx
{
    my ($filestr_ref) = @_;

    &encode($filestr_ref);
    &rewrite_syntax($filestr_ref);
    &decode($filestr_ref);

    return $filestr_ref;
}

unless (caller) { return &main(\@ARGV); }
