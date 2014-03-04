#!/usr/bin/perl -w

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
		);

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

#sub _add_first   { my ($seq, $element) = @_; if (!defined $seq) { die; }             unshift @$seq, $element; return;        }
sub _add_last    { my ($seq, $element) = @_; if (!defined $seq) { die; }             push    @$seq, $element; return;        }
#sub _remove_first{ my ($seq)           = @_; if (!defined $seq) { die; } my $first = shift   @$seq;           return $first; }
#sub _remove_last { my ($seq)           = @_; if (!defined $seq) { die; } my $last  = pop     @$seq;           return $last;  }

if (!defined $ARGV[0])
{ die "usage: macro-system-parser.pl <file>\n"; }

my $k  = qr/[_A-Za-z0-9-]/;
my $wk = qr/[_A-Za-z]$k*[A-Za-z0-9_]*/; # dakota identifier
my $ak = qr/::?$k+/;   # absolute scoped dakota identifier
my $rk = qr/$k+$ak*/;  # relative scoped dakota identifier
my $d = qr/\d+/;  # relative scoped dakota identifier

my $parse_tree = do($ARGV[0]);

#print Dumper $parse_tree;

my $macros = $$parse_tree{'macros'};

my ($name, $body);
while (($name, $body) = each (%$macros))
{
    my $from = $$body{'from'};
    my $to =   $$body{'to'};
    my $num_from_tokens = @$from;
    my $num_to_tokens =   @$to;

    my $filestr = '';
    $filestr .= "sub $name\n";
    $filestr .= "{\n";
    $filestr .= "  my (\$tokens, \$range) = \@_;\n";
    $filestr .= "  my \$first_index = \$\$range[0];\n";
    $filestr .= "  my \$last_index =  \$\$range[1];\n";
    $filestr .= "  my \$num_from_tokens = $num_from_tokens;\n";
    $filestr .= "\n";
    $filestr .= "  for (my \$i = 0; \$i < \$last_index - \$first_index - \$num_from_tokens; \$i++)\n";
    $filestr .= "  {\n";
    $filestr .= "    if (\n";
    for (my $i = 0; $i < $num_from_tokens; $i++)
    {
	my $from_token = $$from[$i];
	if ( $i + 1 < $num_from_tokens)
	{
	    $filestr .= "         '$from_token' eq \$\$tokens[\$first_index + \$i + $i]{'tkn'} &&\n";
	}
	else
	{
	    $filestr .= "         '$from_token' eq \$\$tokens[\$first_index + \$i + $i]{'tkn'}\n";
	}
    }
    $filestr .= "       )\n";
    $filestr .= "    {\n";
    $filestr .= "       my \$to_tokens = [\n";

    for (my $i = 0; $i < $num_to_tokens; $i++)
    {
	my $to_token = $$to[$i];
	$filestr .= "         { 'leading-ws' => [ ' ' ], 'tkn' => '$to_token' },\n";
    }
    $filestr .= "       ];\n";
    $filestr .= "       # todo: pairing up 'from' and 'to' whitespace\n";

	$filestr .= "       splice(\@\$tokens, \$first_index + \$i + 0, \$num_from_tokens, \@\$to_tokens);\n";
    $filestr .= "    }\n";
    $filestr .= "  }\n";
    $filestr .= "  return \$tokens;\n";
    $filestr .= "}\n";
    print $filestr;
}
