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

BEGIN
{
    $prefix = '/usr/local';
    if ($ENV{'DK_PREFIX'})
    { $prefix = $ENV{'DK_PREFIX'}; }

    unshift @INC, "$prefix/lib";
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
$Data::Dumper::Indent    = 0; # default = 2

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
    '?balenced' =>         \&balenced,
    '?balenced-in' =>      \&balenced_in,
    '?block' =>            \&block,
    '?block-in' =>         \&block_in,
    '?dquote-str' =>       \&dquote_str,
    '?ident' =>            \&ident,
    '?ka-ident' =>         \&ka_ident,
    '?list' =>             \&list,
    '?list-in' =>          \&list_in,
    '?list-member-term' => \&list_member_term, # move to a language specific macro
    '?list-member' =>      \&list_member,
    '?type' =>             \&type,
    '?type-ident' =>       \&type_ident,
    '?visibility' =>       \&visibility, # move to a language specific macro
};

my $list_member_term_set = { ',' => 1,
			     ')' => 1  };

my $open_for_close = {
    ')' => '(',
    ']' => '[',
    '}' => '{',
};
my $close_for_open = {
    '(' => ')',
    '[' => ']',
    '{' => '}',
};

my $debug = 0; # 0 or 1 or 2

### start of constraint variable defns
sub list_member_term # move to a language specific macro
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$list_member_term_set{$tkn}) {
	$result = $index;
    }
    return $result;
}

sub list_member
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    #die if $$list_member_term_set{$tkn};
    return -1 if $$list_member_term_set{$tkn};
    my $o = 1;
    my $is_framed = 0;
    my $num_tokens = scalar @{$$sst{'tokens'}};

    while ($num_tokens > $index + $o) {
	$tkn = &sst::at($sst, $index + $o);

	if (!$is_framed) {
	    if ($$list_member_term_set{$tkn}) {
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

sub visibility # move to a language specific macro
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$user_data{'visibilities'}{$tkn})
    { $result = $index; }
    return $result;
}

sub ident
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$k+$/ &&
	!($tkn =~ /^$zt$/))
    { $result = $index; }
    return $result;
}

sub type_ident
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/) # bugbug: requires ab-t at a min (won't allow single char before -t)
    { $result = $index; }
    return $result;
}

sub ka_ident
{
    my ($sst, $index, $user_data) = @_;

    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$user_data{'ka-generics'}{$tkn})
    { $result = $index; }
    return $result;
}

# this is very incomplete
sub type
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/) {
	my $o = 0;
	while ('*' eq &sst::at($sst, $index + $o + 1)) {
	    $o++;
	}
	$result = $index + $o;
    }
    return $result;
}

sub dquote_str
{
    my ($sst, $index, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$dqstr$/) {
	$result = $index;
    }
    return $result;
}

sub block # body is optional since it uses balenced()
{
    my ($sst, $open_token_index, $user_data) = @_;
    return &balenced($sst, $open_token_index, $user_data);
}

sub list # body is optional since it uses balenced()
{
    my ($sst, $open_token_index, $user_data) = @_;
    return &balenced($sst, $open_token_index, $user_data);
}

sub block_in # body is optional since it uses balenced_in() which uses balenced()
{
    my ($sst, $index, $user_data) = @_;
    return &balenced_in($sst, $index, $user_data);
}

sub list_in # body is optional since it uses balenced_in() which uses balenced()
{
    my ($sst, $index, $user_data) = @_;
    return &balenced_in($sst, $index, $user_data);
}

sub balenced
{
    my ($sst, $open_token_index, $user_data) = @_;
    my $close_token_index = $open_token_index;
    my $opens = [];
    my $result = -1;

    while (1)
    {
	my $open_token;
	my $close_token;
        if (&sst::is_open_token($open_token = &sst::at($sst, $close_token_index))) {
	    push @$opens, $open_token;
        }
        elsif (&sst::is_close_token($close_token = &sst::at($sst, $close_token_index))) {
            $open_token = pop @$opens;
	    
	    die if $open_token ne &sst::open_token_for_close_token($close_token);
        }
        if (0 == @$opens) {
	    $result = $close_token_index;
            last;
        }
        $close_token_index++;
    }
    return $result;
}

sub balenced_in
{
    my ($sst, $index, $user_data) = @_;
    die if 0 == $index;
    my $result = &balenced($sst, $index - 1, $user_data);
    if (-1 != $result)
    { $result--; }

    return $result;
}
### end of constraint variable defns

sub macro_expand_recursive
{
    my ($sst, $i, $macros, $macro_name, $user_data, $expanded_macro_names) = @_;
    my $macro = $$macros{$macro_name};

    foreach my $depend_macro_name (@{$$macro{'dependencies'}}) {
	if (!exists($$expanded_macro_names{$depend_macro_name})) {
	    &macro_expand_recursive($sst, $i, $macros, $depend_macro_name, $user_data, $expanded_macro_names);
	    $$expanded_macro_names{$depend_macro_name} = 1;
	}
    }
    my $num_tokens = scalar @{$$sst{'tokens'}};
    foreach my $rule (@{$$macro{'rules'}}) {
	last if $i > $num_tokens - @{$$rule{'lhs'}};

	my ($last_index, $rhs_for_lhs)
	    = &rule_match($sst, $i, $$rule{'lhs'}, $user_data, $macro_name);

	if (-1 != $last_index) {
	    &rule_replace($sst, $i, $last_index, $$rule{'rhs'}, $rhs_for_lhs, $macro_name);
	    last;
	}
    }
}

sub macro_expand
{
    my ($sst, $macros, $user_data) = @_;

    if ($debug) { print STDERR "[", "\n"; }

    for (my $i = 0; $i < @{$$sst{'tokens'}}; $i++) {
	my $expanded_macro_names = {};
	foreach my $macro_name (sort keys %$macros) {
	    &macro_expand_recursive($sst, $i, $macros, $macro_name, $user_data, $expanded_macro_names);
	}
    }
    if ($debug) { print STDERR "]", ",\n"; }
}

sub rhs_dump
{
    my ($seq) = @_;
    my $delim = '';
    my $str = '';

    foreach my $tkn (@$seq) {
	$str .= $delim;
	$str .= "'$$tkn{'str'}'";
	$delim = ',';
    }
    return "\[$str\]";
}

sub debug_str_literal
{
    my ($literal) = @_;
    my $str = '';
    if (2 <= $debug) {
	$str .= "   {";
	$str .= "\n";
	$str .= "    'literal' =>     ";
	$str .= "'$literal'";
	$str .= ",\n";
	$str .= "   }";
	$str .= "\n";
    }
    return $str;
}

sub debug_str_constraint
{
    my ($label, $i, $j, $last_index, $match) = @_;
    my $str = '';
    if (2 <= $debug) {
	$str .= "   {";
	$str .= ",\n";
	
	$str .= "    'constraint' =>  '$label'";
	$str .= ",\n";
	
	$str .= "    'i' =>           '$i'";
	$str .= ",\n";
	
	$str .= "    'j' =>           '$j'";
	$str .= ",\n";
	
	$str .= "    'last-index' =>  '$last_index'";
	$str .= ",\n";
	
	my $match_tokens = [];
	foreach my $m (@$match) { push @$match_tokens, $$m{'str'}; }
	
	$str .= "    'match' =>       ";
	$str .= &Dumper($match_tokens);
	$str .= ",\n";
	$str .= "   }";
	$str .= ",\n";
    }
    return $str;
}

sub debug_print_match
{
    my ($name, $str, $i, $last_index, $lhs, $sst) = @_;
    if ($debug) {
	my $indent = $Data::Dumper::Indent;
	$Data::Dumper::Indent = 0;
	print STDERR " {\n";
	print STDERR "  'macro' =>        '\?$name'", ",\n";
	    
	if (2 <= $debug) {
	    print STDERR "  'details' =>", "\n";
	    print STDERR "  \[", "\n";
	    print STDERR $str;
	    print STDERR "  \]", ",\n";
	}
	    
	print STDERR "  'range' =>         ", &Dumper([$i, $last_index]), ",\n";
	print STDERR "  'pattern' =>       ", &Dumper($lhs), ",\n";
	print STDERR "  'lhs' =>           ", &sst::dump($sst, $i, $last_index), ",\n";
	$Data::Dumper::Indent = $indent;
    }
}

sub debug_print_replace
{
    my ($rhs, $replacement, $lhs_num_tokens) = @_;
    if ($debug) {
	print STDERR "  'template' =>      ", &Dumper($rhs), ",\n";
	print STDERR "  'rhs' =>           ", &rhs_dump($replacement), ",\n";
	my $rhs_num_tokens = scalar @$replacement;
	print STDERR "  'lhs-num-tokens' => '$lhs_num_tokens'", ",\n";
	print STDERR "  'rhs-num-tokens' => '$rhs_num_tokens'", ",\n";
	print STDERR " }", ",\n";
    }
}

sub rule_match
{
    my ($sst, $i, $lhs, $user_data, $name) = @_; # $name is optional
    my $debugstr = '';

    my $last_index = $i;
    my $rhs_for_lhs = {};

    for (my $j = 0; $j < @$lhs; $j++) {
	if ($$lhs[$j] =~ m/^(\?$k+)$/) { # make this re a variable
	    my $label = $1;
	    my $constraint = $$constraints{$label};
	    if (!defined $constraint) { die "Could not find implementation for constraint $label"; }
	    $last_index = &$constraint($sst, $i + $j, $user_data);

	    if (-1 eq $last_index)
	    { $last_index = -1; last; }
	    else {
		# match by constraint
		my $match = [@{$$sst{'tokens'}}[$i + $j..$last_index]];
		$$rhs_for_lhs{$label} = $match;
		if ($debug) { $debugstr .= &debug_str_constraint($label, $i, $j, $last_index, $match); }
	    }
	}
	else {
	    if ($$lhs[$j] ne $$sst{'tokens'}[$i + $j]{'str'})
	    { $last_index = -1; last; }
	    else {
		# match by literal
		my $match = $$lhs[$j];
		$last_index++;
		if ($debug) { $debugstr .= &debug_str_literal($match); }
	    }
	}
    }
    if (-1 != $last_index) { &debug_print_match($name, $debugstr, $i, $last_index, $lhs, $sst); }
    return ($last_index, $rhs_for_lhs);
}

sub rule_replace
{
    my ($sst, $i, $last_index, $rhs, $rhs_for_lhs, $name) = @_; # $name is optional

    my $replacement = [];
    foreach my $rhstkn (@$rhs) {
	if ($rhstkn =~ m/^(\?$k+)$/) { # make this re a variable
	    my $label = $1;
	    if ($$rhs_for_lhs{$label}) {
		push @$replacement, @{$$rhs_for_lhs{$label}};
	    }
	}
	else {
	    push @$replacement, { 'str' => $rhstkn };
	}
    }
    &sst::shift_leading_ws($sst, $i);
    my $lhs_num_tokens = $last_index - $i + 1;
    &debug_print_replace($rhs, $replacement, $lhs_num_tokens);
    splice (@{$$sst{'tokens'}}, $i, $lhs_num_tokens, @$replacement);
}

sub dk_lang_user_data {
    my $user_data;
    if ($ENV{'DK_LANG_USER_DATA'})
    { my $path = $ENV{'DK_LANG_USER_DATA'};
      $user_data = do $path or die "Can not find $path." }
    else
    { my $path = "$prefix/src/dk-lang-user-data.pl";
      $user_data = do $path or die "Can not find $path." }

    return $user_data;
}

unless (caller) {
    my $user_data = &dk_lang_user_data();

    my $macros;
    if ($ENV{'DK_MACROS_PATH'})
    { my $path = $ENV{'DK_MACROS_PATH'};  $macros = do $path or die "Can not find $path." }
    else
    { my $path = "$prefix/src/macros.pl"; $macros = do $path or die "Can not find $path." }

    foreach my $arg (@ARGV)
    {
	my $filestr = &dakota::filestr_from_file($arg);

	my $sst = &sst::make($filestr, $arg);

	&macro_expand($sst, $macros, $user_data);
	print &sst_fragment::filestr($$sst{'tokens'});
    }
};

1;
