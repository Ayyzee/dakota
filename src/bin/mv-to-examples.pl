#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

while (<*.dk>)
{
    my $file = $_;
    my $dir = $file;
    $dir =~ s|\.dk$||g;
    print "mkdir ../examples/$dir\n";
    print "mv $file ../examples/$dir/lib.dk\n";
    print "cp bin+lib-dk ../examples/$dir/bin+lib.dk\n";
}
