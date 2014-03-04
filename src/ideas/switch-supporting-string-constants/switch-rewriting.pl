#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $k = qr/[_A-Za-z0-9-]/; # dakota identifier
my $z = qr/[_A-Za-z]$k*[_A-Za-z0-9]?/;

$main::block = qr{
    \{
    (?:
     (?> [^{}]+ )         # Non-braces without backtracking
     |
     (??{ $main::block }) # Group with matching braces
     )*
     \}
}x;

$main::block_in = qr{
    (?:
     (?> [^{}]+ )         # Non-braces without backtracking
     |
     (??{ $main::block }) # Group with matching braces
     )*
}x;

$main::list = qr{
    \(
    (?:
     (?> [^()]+ )         # Non-parens without backtracking
     |
     (??{ $main::list }) # Group with matching parens
     )*
     \)
}x;

$main::list_in = qr{
    (?:
     (?> [^()]+ )         # Non-parens without backtracking
     |
     (??{ $main::list }) # Group with matching parens
     )*
}x;

my $ENCODED_STRING_BEGIN = '__ENCODED_STRING_BEGIN__';
my $ENCODED_STRING_END =   '__ENCODED_STRING_END__';

undef $/;
$" = '';

my $arg;
foreach $arg (@ARGV)
{
    open FILE, "<$arg" or die "$!\n";
    my $str = <FILE>;
    close FILE;
    $str = &rewrite_switches($str);
    #open FILE, ">$arg" or die "$!\n";
    #print FILE "$str";
    print $str;
}

sub encode_strings
{
    my ($filestr_ref) = @_;
    $$filestr_ref =~ s{(\")((?:[^\"\\]|\\.)*?)(\")}{$1.$ENCODED_STRING_BEGIN.unpack('H*',$2).$ENCODED_STRING_END.$3}gse;
    $$filestr_ref =~ s{(\')((?:[^\'\\]|\\.)*?)(\')}{$1.$ENCODED_STRING_BEGIN.unpack('H*',$2).$ENCODED_STRING_END.$3}gse;
}

sub decode_strings
{
    my ($filestr_ref) = @_;
    $$filestr_ref =~ s{$ENCODED_STRING_BEGIN([A-Za-z0-9]*)$ENCODED_STRING_END}{pack('H*',$1)}gseo;
}

sub make_ident_symbol_scalar
{
    my ($symbol) = @_;
    my $has_word_char;

    if ($symbol =~ m/\w/)
    {
	$has_word_char = 1;
    }
    else
    {
	$has_word_char = 0;
    }

    my $ident_symbol = [ ];

    my $chars = [split //, $symbol];

    foreach my $char (@$chars)
    {
        my $part;
	if ('-' eq $char)
	{
	    if ($has_word_char)
	    { $part = '_'; }
	    else
	    { $part = sprintf("%02x", ord($char)); }
	}
        elsif ($char =~ /$k/)
        { $part = $char; }
	else
	{ $part = sprintf("%02x", ord($char)); }
        &_add_last($ident_symbol, $part);
    }
    my $value = &path::string($ident_symbol);
    $value .= "00";
    return $value;
}
sub make_ident_symbol
{
    my ($seq) = @_;
    my $ident_symbols = [map { &make_ident_symbol_scalar($_) } @$seq];
    &_add_first($ident_symbols, "_");
    return &path::string($ident_symbols);
}
sub path::string
{
    my ($seq) = @_;
    my $string = "@$seq";
    return $string;
}

sub _add_first   { my ($seq, $element) = @_; if (!defined $seq) { die; }             unshift @$seq, $element; return;        }
sub _add_last    { my ($seq, $element) = @_; if (!defined $seq) { die; }             push    @$seq, $element; return;        }
sub _remove_first{ my ($seq)           = @_; if (!defined $seq) { die; } my $first = shift   @$seq;           return $first; }
sub _remove_last { my ($seq)           = @_; if (!defined $seq) { die; } my $last  = pop     @$seq;           return $last;  }

sub _first{ my ($seq) = @_; if (!defined $seq) { die; } my $first = $$seq[0];  return $first; }
sub _last { my ($seq) = @_; if (!defined $seq) { die; } my $last  = $$seq[-1]; return $last;  }

sub switch_replacement_case_dqstr
{
    my ($tbl, $ws1, $str, $ws2) = @_;
    my $n = $$tbl{$str};
    my $result = "case$ws1$n$ws2: /*\"$str\"*/";
    return $result;
}

sub switch_replacement_case_symbol
{
    my ($tbl, $ws1, $str, $ws2) = @_;
    my $n = $$tbl{$str};
    my $result = "case$ws1$n$ws2: /*\$$str*/";
    return $result;
}

sub switch_replacement
{
    my ($ws1, $list_in, $ws2, $block_in) = @_;
    &decode_strings(\$list_in);
    &decode_strings(\$block_in);
    # build index-from-string table
    my $index_tbl = {};
    while ($block_in =~ m/\bcase(\s*)"(.*)"(\s*):/g)
    { $$index_tbl{$2} = 0; }
    while ($block_in =~ m/\bcase(\s*)\$($z)(\s*):/g)
    { $$index_tbl{$2} = 0; }
    my $n = 0; # initial/lowest case label value
    my $labels = [sort keys %$index_tbl];
#    print STDERR &Dumper($labels);
    foreach my $str (@$labels)
    { $$index_tbl{$str} = $n; $n++; }
    # now use index-from-string table to rewrite cases
    while ($block_in =~ s|\bcase(\s*)"(.*)"(\s*):|&switch_replacement_case_dqstr($index_tbl, $1, $2, $3)|ge)
    {}
    while ($block_in =~ s|\bcase(\s*)\$($z)(\s*):|&switch_replacement_case_symbol($index_tbl, $1, $2, $3)|ge)
    {}
    my $func_ident = &make_ident_symbol($labels);
    my $result = "switch$ws1(__mph::$func_ident($list_in))$ws2\{$block_in\}";
    return $result;
}

sub rewrite_switches
{
    my ($str) = @_;
    &encode_strings(\$str);
    $str =~ s/\bswitch(\s*)\(($main::list_in)\)(\s*)\{($main::block_in)\}/&switch_replacement($1, $2, $3, $4)/ges;
    &decode_strings(\$str);
    return $str;
}
