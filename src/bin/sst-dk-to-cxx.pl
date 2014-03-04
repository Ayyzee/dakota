#!/usr/bin/perl -w

my $prefix;
my $SO_EXT;

BEGIN
{
    $prefix = '/usr/local';
    if ($ENV{'DK_PREFIX'})
    { $prefix = $ENV{'DK_PREFIX'}; }

    unshift @INC, "$prefix/lib";

    $SO_EXT = 'so';
    if ($ENV{'SO_EXT'})
    { $SO_EXT = $ENV{'SO_EXT'}; }
};

use strict;
use warnings;

use dakota_util;
use dakota_parse;
use dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

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
    '?param-term' =>  \&param_term,
    '?type' =>        \&type,
    '?visibility' => \&visibility,
    '?ka-default' => \&ka_default,
};

foreach my $arg (@ARGV)
{
    undef $/;
    my $filestr = &dakota::filestr_from_file($arg);
    my $sst = &sst::make($filestr, $arg);
    &macro_expand($sst);

    if (1) {
	print &sst_fragment::filestr($$sst{'tokens'});
    }
    #print Dumper $sst;
    #print $filestr;
    #my $filestr1 = &sst::filestr($sst);
    #print $filestr1;
}

sub param_term
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if (',' eq $tkn ||
	')' eq $tkn)
    {
	$result = $index;
    }
    return $result;
}

sub ka_default
{
    my ($sst, $index) = @_;
    my $tkn;
    my $result = -1;
    my $o = 0;

    # does not deal correctly with , within framing
    while (',' ne ($tkn = &sst::at($sst, $index + $o)) &&
	   ')' ne ($tkn = &sst::at($sst, $index + $o)))
    {
	$result = $index + $o;
	$o++;

	if (scalar @{$$sst{'tokens'}} == $index + $o)
	{
	    $result = -1;
	    last;
	}
    }
    return $result;
}

sub visibility
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ('export'   eq $tkn ||
	'import'   eq $tkn ||
	'noexport' eq $tkn)
    {
	$result = $index;
    }
    return $result;
}

sub ident
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$k+$/ &&
	!($tkn =~ /^$zt$/))
    {
	$result = $index;
    }
    return $result;
}

sub type_ident
{
    my ($sst, $index) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/)
    {
	$result = $index;
    }
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

sub macro_klass_decl
{
    #
    my $lhs = [ 'klass',     '?ident', '{', '?klass-body-in', '}' ];
    my $rhs = [ 'namespace', '?ident',   '{', '?klass-body-in', '}' ];
}

sub macro_expand
{
    my ($sst) = @_;
    my ($lhs, $rhs);

    # import ?dquote-str ;
    # =>
    # #include ?dquote-str
    $lhs = [ 'import', '?dquote-str', ';' ];
    $rhs = [ '#', 'include', '?dquote-str' ];
    &rewrite($sst, $lhs, $rhs);

    # superklass ?ident ;
    # =>
    # /* ... */
    $lhs = [ 'superklass', '?ident', ';' ];
    $rhs = [ ];
    &rewrite($sst, $lhs, $rhs);

    # slots { ... }
    # =>
    # struct slots-t { ... } ;
    $lhs = [ 'slots', '?block' ];
    $rhs = [ 'struct', 'slots-t', '?block', ';' ];
    &rewrite($sst, $lhs, $rhs);

    # ?type => ?ka-default ,|)
    # =>
    # ?type ,|)
    $lhs = [ '?type', '?ident', '=>', '?ka-default', '?param-term' ];
    $rhs = [ '?type', '?ident', '?param-term' ];
    &rewrite($sst, $lhs, $rhs);

    # ?visibility method ?type va : ?ident ?list ?block
    # =>
    # namespace va { ?visibility method ?type ?ident ?list ?block }
    $lhs = [ '?visibility', 'method', '?type', 'va', ':', '?ident', '?list', '?block' ];
    $rhs = [ 'namespace', 'va', '{', '?visibility', 'method', '?type', '?ident', '?list', '?block', '}' ];
    &rewrite($sst, $lhs, $rhs);

    # method ?type ?ident (
    # =>
    # ?type ?ident (
    $lhs = [ 'method', '?type', '?ident', '?list' ];
    $rhs = [            '?type', '?ident', '?list' ];
    &rewrite($sst, $lhs, $rhs);

    # dk:init(super)
    # =>
    # dk:init(super:construct(self,klass))
    $lhs = [ 'dk', ':', '?ident', '(', 'super', ')' ];
    $rhs = [ 'dk', ':', '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', ')' ];
    &rewrite($sst, $lhs, $rhs);

    # dk:init(super,
    # =>
    # dk:init(super:construct(self,klass),
    $lhs = [ 'dk', ':', '?ident', '(', 'super', ',' ];
    $rhs = [ 'dk', ':', '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', ',' ];
    &rewrite($sst, $lhs, $rhs);

    # self.ident
    # =>
    # unbox(self)->ident
    $lhs = [ 'self', '.', '?ident' ];
    $rhs = [ 'unbox', '(', 'self', ')', '->', '?ident' ];
    &rewrite($sst, $lhs, $rhs);

    # throw make
    # =>
    # throw dk-current-exception = make
    $lhs = [ 'throw', 'make' ];
    $rhs = [ 'throw', 'dk-current-exception', '=', 'make' ];
    &rewrite($sst, $lhs, $rhs);
    
    # ident:box({...})
    # =>
    # ident:box(ident:construct(...))
    $lhs = [ '?ident', ':', 'box', '(', '{', '?block-in', '}', ')' ];
    $rhs = [ '?ident', ':', 'box', '(', 'ident', ':', 'construct', '(', '?block-in', ')', ')' ];
    &rewrite($sst, $lhs, $rhs);

    # make ( ... )
    # =>
    # dk:init(dk:alloc( ... ))
    $lhs = [ 'make', '(', '?list-in', ')' ];
    $rhs = [ 'dk', ':', 'init', '(', 'dk', ':', 'alloc', '(', '?list-in', ')', ')' ];
    &rewrite($sst, $lhs, $rhs);

    # export enum ?type-ident ?block
    # =>
    # /* ... */
    $lhs = [ 'export', 'enum', '?type-ident', '?block' ];
    $rhs = [ ];
    &rewrite($sst, $lhs, $rhs);

    # method alias(...)
    # =>
    # method /* alias(...) */
    $lhs = [ 'method', 'alias', '?list' ];
    $rhs = [ 'method' ];
    &rewrite($sst, $lhs, $rhs);

    # foo:slots-t* slt = unbox(bar)
    # becomes
    # foo:slots-t* slt = foo:unbox(bar)

    # foo:slots-t& slt = *unbox(bar)
    # becomes
    # foo:slots-t& slt = *foo:unbox(bar)

    # foo-t* slt = unbox(bar)
    # becomes
    # foo-t* slt = foo:unbox(bar)

    # foo-t& slt = *unbox(bar)
    # becomes
    # foo-t& slt = *foo:unbox(bar)
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

sub rewrite
{
    my ($sst, $lhs, $rhs) = @_;

    # input index
    for (my $i = 0; $i < (@{$$sst{'tokens'}} - @$lhs); $i++) {
	my $did_match = 1;
	my $replacement = [];
	my $rhs_for_lhs = {};
	my ($first_index, $last_index);
	$first_index = $i;
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
		{ $did_match = 0; last; }
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
