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

my $debug = 0; # 0 or 1 or 2 or 3

### start of constraint variable defns
sub list_member_term # move to a language specific macro
{
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$user_data{'list'}{'member'}{'term'}{$tkn}) {
	$result = $index;
    }
    return $result;
}

sub list_member
{
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    #die if $$user_data{'list'}{'member'}{'term'}{$tkn};
    return -1 if $$user_data{'list'}{'member'}{'term'}{$tkn};
    my $o = 1;
    my $is_framed = 0;
    my $num_tokens = scalar @{$$sst{'tokens'}};

    while ($num_tokens > $index + $o) {
	$tkn = &sst::at($sst, $index + $o);

	if (!$is_framed) {
	    if ($$user_data{'list'}{'member'}{'term'}{$tkn}) {
		return $index + $o - 1;
	    }
	}
	if ($$user_data{'list'}{'open'} eq $tkn) {
	    $is_framed++;
	}
	elsif ($$user_data{'list'}{'close'} eq $tkn && $is_framed) {
	    $is_framed--;
	}
	$o++;
    }
    return -1;
}

sub visibility # move to a language specific macro
{
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$user_data{'visibility'}{$tkn})
    { $result = $index; }
    return $result;
}

sub ident
{
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$k+$/ &&
	(-1 == &type_ident($sst, $index, $constraint, $user_data))) # should be removed
    { $result = $index; }
    return $result;
}

sub type_ident
{
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$zt$/) # bugbug: requires ab-t at a min (won't allow single char before -t)
    { $result = $index; }
    return $result;
}

sub ka_ident
{
    my ($sst, $index, $constraint, $user_data) = @_;

    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($$user_data{'ka-ident'}{$tkn})
    { $result = $index; }
    return $result;
}

# this is very incomplete
sub type
{
    my ($sst, $index, $constraint, $user_data) = @_;
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
    my ($sst, $index, $constraint, $user_data) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn =~ /^$dqstr$/) {
	$result = $index;
    }
    return $result;
}

sub block # body is optional since it uses balenced()
{
    my ($sst, $open_token_index, $constraint, $user_data) = @_;
    return &balenced($sst, $open_token_index, $constraint, $user_data);
}

sub list # body is optional since it uses balenced()
{
    my ($sst, $open_token_index, $constraint, $user_data) = @_;
    return &balenced($sst, $open_token_index, $constraint, $user_data);
}

sub block_in # body is optional since it uses balenced_in() which uses balenced()
{
    my ($sst, $index, $constraint, $user_data) = @_;
    return &balenced_in($sst, $index, $constraint, $user_data);
}

sub list_in # body is optional since it uses balenced_in() which uses balenced()
{
    my ($sst, $index, $constraint, $user_data) = @_;
    return &balenced_in($sst, $index, $constraint, $user_data);
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
    my ($sst, $index, $constraint, $user_data) = @_;
    die if 0 == $index;
    my $result = &balenced($sst, $index - 1, $constraint, $user_data);
    if (-1 != $result)
    { $result--; }

    return $result;
}
### end of constraint variable defns

sub macro_expand_recursive
{
    my ($sst, $i, $macros, $macro_name, $expanded_macro_names, $user_data) = @_;
    my $macro = $$macros{$macro_name};
    my $change_count = 0;

    foreach my $depend_macro_name (@{$$macro{'dependencies'}}) {
	if (!exists($$expanded_macro_names{$depend_macro_name})) {
	    $change_count += &macro_expand_recursive($sst, $i, $macros, $depend_macro_name,
						     $expanded_macro_names, $user_data);
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
	    $change_count++;
	    last;
	}
    }
    return $change_count;
}

sub macro_expand
{
    my ($sst, $i, $macros, $user_data) = @_;
    my $change_count = 0;

    foreach my $macro_name (sort keys %$macros) {
	if ($change_count = &macro_expand_recursive($sst, $i, $macros, $macro_name,
						    {}, $user_data))
	{ last; }
    }
    return $change_count;
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

sub debug_str_match
{
    my ($i, $j, $last_index, $match, $constraint) = @_;
    my $str = '';
    if (2 <= $debug) {
	$str .= "   {";
	$str .= "\n";
	
	if ($constraint) {
	    $str .= "    'constraint' =>  '$constraint'";
	    $str .= ",\n";
	}
	
	my $match_tokens = [];
	foreach my $m (@$match) { push @$match_tokens, $$m{'str'}; }

	$str .= "    'match' =>       ";
	$str .= &Dumper($match_tokens);
	$str .= ",\n";
	$str .= "    'i' =>           '$i'";
	$str .= ",\n";
	
	$str .= "    'j' =>           '$j'";
	$str .= ",\n";
	
	$str .= "    'last-index' =>  '$last_index'";
	$str .= ",\n";

	$str .= "   }";
	$str .= ",\n";
    }
    return $str;
}

sub debug_print_match
{
    my ($name, $str2, $str3, $i, $last_index, $lhs, $sst) = @_;

    if ($debug >= 2 || $last_index != -1 && $debug >= 1) {
	my $indent = $Data::Dumper::Indent;
	$Data::Dumper::Indent = 0;
	print STDERR " {\n";
	print STDERR "  'macro' =>        '\?$name'", ",\n";
	    
	if (2 <= $debug && ('' ne $str2 || '' ne $str3)) {
	    print STDERR "  'details' =>", "\n";
	    print STDERR "  \[", "\n";
	    print STDERR $str2;
	    if (3 <= $debug) {
		print STDERR $str3;
	    }
	    print STDERR "  \]", ",\n";
	}
	    
	print STDERR "  'range' =>         ", &Dumper([$i, $last_index]), ",\n";
	print STDERR "  'pattern' =>       ", &Dumper($lhs), ",\n";
	print STDERR "  'lhs' =>           ", &sst::dump($sst, $i, $last_index), ",\n";
	$Data::Dumper::Indent = $indent;

	if (-1 == $last_index) {
	    print STDERR " },\n";
	}
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

sub literal
{
    my ($sst, $index, $literal) = @_;
    my $tkn = &sst::at($sst, $index);
    my $result = -1;

    if ($tkn eq $literal) {
	$result = $index;
    }
    return $result;
}

sub rule_match
{
    my ($sst, $i, $lhs, $user_data, $name) = @_; # $name is optional
    my $debug2_str = '';
    my $debug3_str = '';

    my $prev_last_index = $i;
    my $last_index = $i;
    my $rhs_for_lhs = {};

    for (my $j = 0; $j < @$lhs; $j++) {
	my $constraint_name;
	if ($$lhs[$j] =~ m/^\?$k+$/) {
	    my $constraint = $$constraints{$$lhs[$j]};
	    if (!defined $constraint) { die "Could not find implementation for constraint $$lhs[$j]"; }
	    # match by constraint
	    $last_index = &$constraint($sst, $prev_last_index, $$lhs[$j], $user_data);
	    $constraint_name = $$lhs[$j]
	}
	else {
	    # match by literal
	    $last_index = &literal($sst, $prev_last_index, $$lhs[$j]);
	    $constraint_name = undef;
	}

	if (-1 != $last_index) {
	    my $match = [@{$$sst{'tokens'}}[$prev_last_index..$last_index]];
	    $$rhs_for_lhs{$$lhs[$j]} = $match;
	    if (2 <= $debug) { $debug2_str .= &debug_str_match($i, $j, $last_index,
							       $match, $constraint_name); }
	    $prev_last_index = $last_index + 1;
	}
	else {
	    if (3 <= $debug) { $debug3_str .= &debug_str_match($i, $j, $last_index, 
							       undef, $constraint_name); }
	    last;
	}
    }
    &debug_print_match($name, $debug2_str, $debug3_str, $i, $last_index, $lhs, $sst);
    return ($last_index, $rhs_for_lhs);
}

sub rule_replace
{
    my ($sst, $i, $last_index, $rhs, $rhs_for_lhs, $name) = @_; # $name is optional

    my $replacement = [];
    foreach my $rhstkn (@$rhs) {
	my $tkns = $$rhs_for_lhs{$rhstkn};
	if (!$tkns) { # these are tokens that exists only in the rhs and not in the lhs
	    $tkns = [{ 'str'         => $rhstkn,
		       'leading-ws'  => '',
		       'trailing-ws' => '' }];
	}
	push @$replacement, @$tkns;
    }
    &sst::shift_leading_ws($sst, $i);
    my $lhs_num_tokens = $last_index - $i + 1;
    &debug_print_replace($rhs, $replacement, $lhs_num_tokens);
    splice (@{$$sst{'tokens'}}, $i, $lhs_num_tokens, @$replacement);
    #&sst::splice($sst, $i, $lhs_num_tokens, $replacement);
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

	if ($debug) { print STDERR "[", "\n"; }

	for (my $i = 0; $i < @{$$sst{'tokens'}}; $i++) {
	    while (&macro_expand($sst, $i, $macros, $user_data))
	    {}
	}
	if ($debug) { print STDERR "]", ",\n"; }

	print &sst_fragment::filestr($$sst{'tokens'});
    }
};

1;
