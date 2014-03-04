#!/usr/bin/perl -w

use strict;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent    = 1; # default = 2

$main::block = qr{
    \{
    (?:
     (?> [^{}]+ )         # Non-braces without backtracking
     |
     (??{ $main::block }) # Group with matching braces
     )*
     \}
}x;

my $type2file = {};
my $overview = {};

undef $/;

# typedef struct { ... } a_t;
# typedef struct a_t b_t;
# typedef unsigned int uint_t;
# struct c_t { ... };

while (<>) {
    my $file = $ARGV;
    while (m/\btypedef\b([^;{}]+)\b(\w+)\s*;/gs) {
	my $type = $2;
	my $info = "typedef ... $2 ;";
	$$overview{$info} = $file;
	$$type2file{$type} = { 'file' => $file, 'info' => $info };
    }
    #pos $_ = 0;
    while (m/\btypedef\s+(struct|union|enum)\s*($main::block)\s*(\w+)\s*;/gs) {
	my $type = "$3";
	my $info = "typedef $1 { ... } $3 ;";
	$$overview{$info} = $file;
	$$type2file{$type} = { 'file' => $file, 'info' => $info };
    }
    #pos $_ = 0;
    while (m/\b(struct|union|enum)\s+(\w+)\s*($main::block)/gs) {
	my $type = "$2";
	my $info = "$1 $2 { ... } ;";
	$$overview{$info} = $file;
	$$type2file{$type} = { 'file' => $file, 'info' => $info };
    }
}
print &Dumper($type2file);
#print &Dumper($overview);
