#!/usr/bin/perl -w -I ../bin -I /usr/local/dakota/bin

use strict;
use Dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
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

my $k  = qr/[_a-z0-9-]+/; # dakota identifer
my $ak = qr/:$k/;     # absolute scoped dakota identifier
my $rk = qr/$k$ak*/;  # relative scoped dakota identifier

undef $/;
my $infilestr = <STDIN>;

$infilestr =~ s| *(__klass)\s+($k)\s*($main::block)|&convert_klass_to_adt($1, $2, $3)|gse;
print $infilestr;

sub
convert_klass_to_adt
{
    my ($type, $name, $block) = @_;

    $block =~ s|\{(.*)\}|$1|s;
    $block =~ s|__slots(\s*\{.*?\})|struct $name-t$1;|s;
    $block =~ s| *__method\s+__alias.*?;\n||g;
    $block =~ s|(__method\s+[^(]+?)\s*($k\()|$1 $name-$2|g;

    return "$block";
}
