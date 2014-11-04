#!/usr/bin/perl -w

# Copyright (C) 2007, 2008, 2009 Robert Nielsen <robert@dakota.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

my $prefix;
my $kw_arg_generics;
my $macros;

BEGIN
{
    $prefix = '/usr/local';
    if ($ENV{'DK_PREFIX'})
    { $prefix = $ENV{'DK_PREFIX'}; }

    unshift @INC, "$prefix/lib";

    if ($ENV{'DK_KA_GENERICS'})
    { $kw_arg_generics = do $ENV{'DK_KA_GENERICS'}; }
    else
    { $kw_arg_generics = do "$prefix/src/ka-generics.pl"; }

    if ($ENV{'DK_MACROS_PATH'})
    { $macros = do $ENV{'DK_MACROS_PATH'}; }
    else
    { $macros = do "$prefix/src/macros.pl"; }
};

package dakota;

use strict;
use warnings;

use dakota_sst;
use dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

our @ISA = qw(Exporter);
our @EXPORT= qw(
		macro_expand
		);

my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]/;
my $zt = qr/$z-t/;
# not-escaped " .*? not-escaped "
my $dqstr = qr/(?<!\\)".*?(?<!\\)"/;

my $constraints =
{
    '?ident' =>       \&ident,
    '?type-ident' =>  \&type_ident,
    '?dquote-str' =>  \&dquote_str,
    '?balenced' =>    \&balenced,
    '?balenced-in' => \&balenced_in,
    '?block' =>       \&block,
    '?block-in' =>    \&block_in,
    '?list' =>        \&list,
    '?list-in' =>     \&list_in,
    '?arg-term' =>    \&arg_term,
    '?type' =>        \&type,
    '?visibility' =>  \&visibility,
    '?arg' =>         \&arg,
    '?ka-ident' =>    \&ka_ident,
};

sub arg_term
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if (',' eq $tkn ||
	')' eq $tkn)
    { $result = $index; }
    return $result;
}

sub arg
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    die if (',' eq $tkn || ')' eq $tkn);
    my $o = 1;
    my $is_framed = 0;
    my $num_tokens = scalar @{$$sst{'tokens'}};

    while ($num_tokens > $index + $o) {
	$tkn = &sst::at($sst, $index + $o);

	if (!$is_framed) {
	    if (',' eq $tkn || ')' eq $tkn) {
		return $index + $o - 1;
	    }
	}
	if ('(' eq $tkn) {
	    $is_framed++;
	}
	elsif (')' eq $tkn && $is_framed) {
	    $is_framed--;
	}
	$o++;
    }
    return -1;
}

sub visibility
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ('export'   eq $tkn ||
	'import'   eq $tkn ||
	'noexport' eq $tkn)
    { $result = $index; }
    return $result;
}

sub ident
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$k+$/ &&
	!($tkn =~ /^$zt$/))
    { $result = $index; }
    return $result;
}

sub type_ident
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/)
    { $result = $index; }
    return $result;
}

sub ka_ident
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if (exists $$kw_arg_generics{$tkn})
    { $result = $index; }
    return $result;
}

sub type
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/)
    {
	my $o = 0;
	while ('*' eq &sst::at($sst, $index + $o + 1))
	{
	    $o++;
	}
	$result = $index + $o;
    }
    return $result;
}

sub dquote_str
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$dqstr$/)
    {
	$result = $index;
    }
    return $result;
}

sub block
{
    my ($sst, $open_token_index) = @_;
    return &balenced($sst, $open_token_index);
}
sub list
{
    my ($sst, $open_token_index) = @_;
    return &balenced($sst, $open_token_index);
}

sub block_in
{
    my ($sst, $index) = @_;
    return &balenced_in($sst, $index);
}

sub list_in
{
    my ($sst, $index) = @_;
    return &balenced_in($sst, $index);
}
sub balenced
{
    my ($sst, $open_token_index) = @_;
    my $close_token_index = $open_token_index;
    my $opens = [];
    my $result = -1;

    while (1)
    {
	my $open_token;
	my $close_token;
        if (&sst::is_open_token($open_token = &sst::at($sst, $close_token_index)))
        {
	    push @$opens, $open_token;
        }
        elsif (&sst::is_close_token($close_token = &sst::at($sst, $close_token_index)))
        {
            $open_token = pop @$opens;
	    
	    die if $open_token ne &sst::open_token_for_close_token($close_token);
        }
        if (0 == @$opens)
        {
	    $result = $close_token_index;
            last;
        }
        $close_token_index++;
    }
    return $result;
}
sub balenced_in
{
    my ($sst, $index) = @_;

    my $result = &balenced($sst, $index - 1);
    if (-1 != $result)
    { $result--; }

    return $result;
}

sub macro_expand_recursive
{
    my ($sst, $macros, $macro_name, $expanded_macro_names) = @_;
    my $info = $$macros{$macro_name};

    foreach my $depend_macro_name (@{$$info{'dependencies'}}) {
	#print "depend-macro-name = $depend_macro_name\n";
	if (!exists($$expanded_macro_names{$depend_macro_name})) {
	    &macro_expand_recursive($sst, $macros, $depend_macro_name, $expanded_macro_names);
	    $$expanded_macro_names{$depend_macro_name} = 1;
	    #print "depend-macro-name = $depend_macro_name\n";
	}
    }
    &sst_rewrite($sst, $$info{'lhs'}, $$info{'rhs'}, $macro_name); # $macro_name is optional
}

sub macro_expand
{
    my ($sst, $macros) = @_;
    my $expanded_macro_names = {};

    foreach my $macro_name (sort keys %$macros) {
	&macro_expand_recursive($sst, $macros, $macro_name, $expanded_macro_names);
    }
}

sub sst_dump
{
    my ($sst, $begin_index, $end_index) = @_;

    my $str = '';

    for (my $i = $begin_index; $i <= $end_index; $i++)
    {
	$str .= ' ';
	$str .= &sst::at($sst, $i);
    }
    if ($str =~ m/\S/)
    {
	print STDERR "$str\n";
    }
}

sub sst_rewrite
{
    my ($sst, $lhs, $rhs, $name) = @_; # $name is optional

    if (0) {
	my $indent = $Data::Dumper::Indent;
	$Data::Dumper::Indent = 0;
	print "'$name':\n";
	print "  ", &Dumper($lhs), "\n";
	print "  ", &Dumper($rhs), "\n";
	$Data::Dumper::Indent = $indent;
    }

    # input index
    for (my $i = 0; $i < (@{$$sst{'tokens'}} - @$lhs); $i++) {
	my $did_match = 1;
	my $replacement = [];
	my $rhs_for_lhs = {};
	my ($first_index, $last_index) = ($i, $i);
	# lhs index
	for (my $j = 0; $j < @$lhs; $j++) {
#	    print "  $i, $j\n";
#	    print "  $$lhs[$j] <=> $$sst{'tokens'}[$i + $j]{'str'}\n";	    
	    if ($$lhs[$j] =~ m/\?($k+)/) {
		my $cname = "?$1";
		my $label = "?$1";
		my $constraint = $$constraints{$cname};
		$last_index = &$constraint($sst, $i + $j);
		#&sst_dump($sst, $i + $j, $last_index);
#		print "  $last_index = constraint(sst, $i + $j)\n";
		if (-1 eq $last_index)
		{ $did_match = 0; $last_index = $first_index; last; }
		else {
#		    print "*\n";
		    $$rhs_for_lhs{$label} = [@{$$sst{'tokens'}}[$i + $j..$last_index]];
#		    print Dumper $rhs_for_lhs;
		    $i += $last_index - ($i + $j);
		}
	    }
	    else {
		if ($$lhs[$j] ne $$sst{'tokens'}[$i + $j]{'str'})
		{ $did_match = 0; last;	}
		else {
#		    print "*\n";
		    $last_index++;
		}
	    }
	}
	if ($did_match)	{
	    foreach my $rhstkn (@$rhs) {
		if ($rhstkn =~ m/\?($k+)/) {
		    my $label = "?$1";
		    if ($$rhs_for_lhs{$label}) {
			push @$replacement, @{$$rhs_for_lhs{$label}};
		    }
		}
		else {
		    push @$replacement, { 'str' => $rhstkn };
		}
	    }
	    &sst::shift_leading_ws($sst, $first_index);
	    splice (@{$$sst{'tokens'}}, $first_index, $last_index - $first_index + 1, @$replacement);
	    $i = 0;
	}
    }
}

sub __main__
{
    foreach my $arg (@ARGV)
    {
	undef $/;
	my $filestr = &dakota::filestr_from_file($arg);

	my $sst = &sst::make($filestr, $arg);
	&macro_expand($sst, $macros);
	print &sst_fragment::filestr($$sst{'tokens'});
    }
    return 0;
}

unless (caller) { exit &__main__(); }

1;
