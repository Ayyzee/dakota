#!/usr/bin/perl -w

# prefix = /usr/local
BEGIN
{
    unshift @INC, (exists $ENV{'DK_NO_PREFIX'} ? "bin" : "/usr/local/bin");
    unshift @INC, (exists $ENV{'DK_NO_PREFIX'} ? "lib" : "/usr/local/lib");
};

use strict;
use warnings;

use dakota;
use dakota_parse;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

undef $/;
my $filestr = <STDIN>;
my $tokens = &dakota::tokens_from_filestr($filestr);
#print Dumper $tokens;
$" = '';

my $token_context;
foreach $token_context (@$tokens)
{
    print "@{$$token_context{'leading-ws'}}";
    print $$token_context{'tkn'};
}
print "\n";
