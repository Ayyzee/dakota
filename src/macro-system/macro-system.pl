#!/usr/bin/perl -w

my $prefix;
my $SO_EXT;

BEGIN
{
    $prefix = '/usr/local';
    if ($ENV{'DK_PREFIX'})
    { $prefix = $ENV{'DK_PREFIX'}; }

    unshift @INC, "$prefix/lib";
    unshift @INC, "../../lib";

    $SO_EXT = 'so';
    if ($ENV{'SO_EXT'})
    { $SO_EXT = $ENV{'SO_EXT'}; }
};

use strict;
use warnings;

use dakota_util;
use dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 0; # default = 2

my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]+$k*[_A-Za-z0-9]*/;
my $az = qr/::?$z/;   # absolute scoped dakota identifier
my $rz = qr/$z$az*/;  # relative scoped dakota identifier
my $zt = qr/$z-t/;
# not-escaped " .*? not-escaped "
my $dqstr = qr/(?<!\\)".*?(?<!\\)"/;
my $string_object_re = qr/\$(?<!\\)".*?(?<!\\)"/;
my $symbol_re = qr/\$$z/;

my $gbl_constraints =
{
    '?ident' =>            \&ident,
    '?token' =>            \&token,
    '?type-ident' =>       \&type_ident,
#    '?qual-type-ident' =>  \&qual_type_ident,
    '?string' =>           \&string,
    '?string-object' =>    \&string_object,
    '?symbol' =>           \&symbol,
#    '?qual-type' =>       \&qual_type,
    '?wildcard' =>         \&wildcard,
};
my $gbl_aliases = {};

my $gbl_constraint_context = undef;
my $gbl_col = 0;
my $gbl_should_echo = 0;
my $gbl_should_echo_summary = 0;
my $gbl_macros_file = $ENV{'MACROS'};
my $gbl_macros = &dakota::scalar_from_file($gbl_macros_file);

#print Dumper $gbl_macros; print "\n";
foreach my $arg (@ARGV) {
    my $filestr = &dakota::filestr_from_file($arg);
    my $sst = &sst::make($filestr, $arg);
    #print Dumper $sst; print "\n";
    #print &sst_fragment::filestr($$sst{'tokens'});
    &macros::expand($sst, $gbl_macros);
    print &sst_fragment::filestr($$sst{'tokens'});
    #print Dumper $sst; print "\n";
}

sub constraint
{
    my ($token) = @_;
    my $constraint;

    #print STDERR Dumper $gbl_aliases;

    if (exists $$gbl_constraints{$token}) {
	$constraint = $$gbl_constraints{$token}; # a sub
    }
    elsif (exists $$gbl_aliases{$token}) {
	my $constraint_name = $$gbl_aliases{$token};
	$constraint = $$gbl_constraints{$constraint_name};
    }
    else {
	print STDERR "using default constraint ?token\n";
	$constraint = $$gbl_constraints{'?token'}; # default constraint
    }
    return $constraint;
}
sub constraint_name
{
    my ($token) = @_;
    my $name = $token;

    #print STDERR Dumper $gbl_aliases;

    if (exists $$gbl_aliases{$token}) {
	$name = $$gbl_aliases{$token};
    }
    return $name;
}
sub constraint_context::make
{
    my ($name, $constraint, $sst, $range, $udata) = @_;
    my $result = { 'name' => $name, 'constraint' => $constraint,
		   'sst' => $sst, 'range' => $range, 'udata' => $udata };
    return $result;
}

sub constraint_context::print
{
    my ($constraint_context) = @_;
    die if !defined $constraint_context;

    my $name = $$constraint_context{'name'};
    my $range = $$constraint_context{'range'};
    &print_in_col($gbl_col, "$name(");
    &range::print($range);
    print ")";
}

sub constraint_context::println
{
    my ($constraint_context) = @_;
    &constraint_context::print($constraint_context);
    print "\n";
}

sub match
{
    my ($sst, $range, $match_token) = @_;

    my ($result_lhs, $result_rhs) = (undef, []);
    my $token = &sst::at($sst, $$range[0]);
    if ($token && ($token eq $match_token)) {
	$result_lhs = [ $$range[0], $$range[0] ];
	push @$result_rhs, $token;
    }
    if ($gbl_should_echo) {
	if ($gbl_constraint_context)
	{ &constraint_context::print($gbl_constraint_context); }
	if ($token && $result_lhs) {
	    print ": '$token' <=> '$match_token' = ";
	    &range::println($result_lhs);
	}
	elsif ($token) {
	    print ": '$token' <=> '$match_token' = undef";
	    print "\n";
	}
    }
    return ($result_lhs, $result_rhs);
}

sub match_re
{
    my ($sst, $range, $match_re) = @_;

    my ($result_lhs, $result_rhs) = (undef, []);
    my $token = &sst::at($sst, $$range[0]);
    if ($token && ($token =~ /$match_re/)) {
	$result_lhs = [ $$range[0], $$range[0] ];
	push @$result_rhs, $token;
    }
    if ($gbl_should_echo) {
	if ($gbl_constraint_context)
	{ &constraint_context::print($gbl_constraint_context); }
	if ($token && $result_lhs) {
	    print ": '$token' <=> RE = ";
	    &range::println($result_lhs);
	}
	elsif ($token) {
	    print ": '$token' <=> RE = undef";
	    print "\n";
	}
    }
    return ($result_lhs, $result_rhs);
}

sub ident
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = &match_re($sst, $range, $z);
    return ($result_lhs, $result_rhs);
}

sub token
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = (undef, []);
    my $token = &sst::at($sst, $$range[0]);
    $result_lhs = [ $$range[0], $$range[0] ];
    push @$result_rhs, $token;
    return ($result_lhs, $result_rhs);
}

sub type_ident
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = &match_re($sst, $range, $zt);
    return ($result_lhs, $result_rhs);
}

sub wildcard
{
    my ($sst, $range, $next_token) = @_;
    my ($result_lhs, $result_rhs) = (undef, []);
    my $close_token_index = $$range[0];
    my $stk = 0;
    die if !$next_token;

    while ($close_token_index <= $$range[1]) {
	my $token = &sst::at($sst, $close_token_index);

	#print STDERR "next-token=$next_token, token=$token\n";
	if ($stk == 0 && ($next_token eq $token)) {
	    last;
	}
	if ($stk == 0 && ($next_token ne $token) && &sst::is_close_token($token)) {
	    return (undef, []);
	}
        if (&sst::is_open_token($token)) {
	    $stk++;
        }
        elsif (&sst::is_close_token($token)) {
	    $stk--;
	}
	push @$result_rhs, $token;
	$close_token_index++;
    }
    $result_lhs = [ $$range[0], $close_token_index - 1 ];

    return ($result_lhs, $result_rhs);
}

sub string
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = &match_re($sst, $range, $dqstr);
    return ($result_lhs, $result_rhs);
}

sub string_object
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = &match_re($sst, $range, $string_object_re);
    return ($result_lhs, $result_rhs);
}

sub symbol
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = &match_re($sst, $range, $symbol_re);
    return ($result_lhs, $result_rhs);
}

sub balenced
{
    my ($sst, $range) = @_;
    my ($result_lhs, $result_rhs) = (undef, []);
    my $close_token_index = $$range[0];
    my $opens = [];

    while ($close_token_index <= $$range[1]) {
	my $token = &sst::at($sst, $close_token_index);

        if (&sst::is_open_token($token)) {
            push @$opens, $token;
        }
        elsif (&sst::is_close_token($token)) {
            my $open_token = pop @$opens;

	    if (!defined $open_token)
	    { return undef; }

            die if $open_token ne &sst::open_token_for_close_token($token);
        }
	push @$result_rhs, $token;
	
        if (0 == @$opens) {
            $result_lhs = [ $$range[0], $close_token_index ];
            last;
        }
        $close_token_index++;
    }
    return ($result_lhs, $result_rhs);
}

sub sst::rewrite
{
    my ($sst, $lhs_range, $rhs_templ, $tbl) = @_;

    if ($gbl_should_echo_summary) {
	print '1/3: ', Dumper $lhs_range; print "\n";
	print '2/3: ', Dumper $rhs_templ; print "\n";
	print '3/3: ', Dumper $tbl; print "\n";
    }
    my $rhs = [];

    for(my $i = 0; $i < @$rhs_templ; $i++) {
	if ($$rhs_templ[$i] =~ m/^\?/) {
	    my $replacement = $$tbl{$$rhs_templ[$i]};
	    die if !$replacement;
	    push @$rhs, @$replacement;
	}
	else {
	    push @$rhs, $$rhs_templ[$i];
	}
    }
    if ($gbl_should_echo_summary) {
	print '===: ', Dumper $rhs; print "\n";
    }
  
    my $offset = $$lhs_range[0];
    my $length = $$lhs_range[1] - $$lhs_range[0] + 1;

    &sst::splice($sst, $offset, $length, $rhs);
}

sub println_in_col
{
    my ($col, $str) = @_;
    &print_in_col($col, $str);
    print "\n";
}

sub print_in_col
{
    my ($col, $str) = @_;
    print '  ' x $col;
    print "$str";
}

sub dump # recursive
{
    my ($sst, $rule_name, $rules, $sub_rules, $col) = @_;
    if (0 == $col) {
	&println_in_col($col, "$rule_name (macro)");
    }
    else {
	&println_in_col($col, "$rule_name (sub-rule)");
    }
    my $rule_num = 0;

    foreach my $rule (@$rules) {
	if (0 != $rule_num)
	{ &println_in_col($col + 1, "--"); }
	$rule_num++;
	if (0 != @{$$rule{'lhs'}} &&
	    0 == $col) {
	    my $intro_tkn = $$rule{'lhs'}[0];
	    &println_in_col($col + 1, "$intro_tkn (intro-tkn)");
	}
	if (0 == scalar @{$$rule{'lhs'}}) 
	{ &println_in_col($col + 1, "<empty>"); }
	foreach my $tkn (@{$$rule{'lhs'}}) {
	    if ($tkn =~ m/^\?recurse$/) {
		&println_in_col($col + 1, "(recursive)");
	    }
	    elsif ($tkn =~ m/^\?/) {
		if ($$sub_rules{$tkn})	{
		    &dump($sst, $tkn, $$sub_rules{$tkn}, $sub_rules, $col + 1); # recurse
		}
		elsif (&constraint($tkn)) {
		    &println_in_col($col + 1, "$tkn (constraint)");
		}
		else {
		    &println_in_col($col + 1, "$tkn (unknown)");
		}
	    }
	    else {
		&println_in_col($col + 1, "$tkn (token)");
	    }
	}
    }
}

sub macros::expand
{
    my ($sst, $macros) = @_;
    my $names = [keys %$macros];

    for(my $i = 0; $i < &sst::size($sst); ) {
	for(my $j = 0; $j < @$names; ) {
	    my $name = $$names[$j];
	    $gbl_aliases = $$macros{$name}{'aliases'};
	    my ($lhs_range, $rhs_rule, $tbl) = &rules::expand($sst, [$i, &sst::size($sst) - 1],
							      [ $name ], $$macros{$name}{'rules'},
							      $$macros{$name}{'sub-rules'}, 0);
	    if ($lhs_range) {
		&sst::rewrite($sst, $lhs_range, $rhs_rule, $tbl);
		$j = 0;
	    }
	    else {
		$j++;
	    }
	}
	$i++;
    }
}

sub range::print
{
    my ($range) = @_;
    die if !defined $range;
    print "\[$$range[0],$$range[1]\]";
}

sub range::println
{
    my ($range) = @_;
    &range::print($range);
    print "\n";
}

sub constraint::expand
{
    my ($name, $tkn, $constraint, $sst, $range, $udata) = @_;
    $gbl_constraint_context = &constraint_context::make($name, $constraint, $sst, $range, $udata);
    my ($result_lhs, $result_rhs) = &$constraint($sst, $range, $udata);
    if ($result_lhs && $gbl_should_echo) {
	&constraint_context::print($gbl_constraint_context);
	print " = (";
	&range::print($result_lhs);
	print ",";
	print Dumper $result_rhs;
	print ")\n";
    }
    my $tbl;
    if ($tkn) {
	$tbl = { $tkn => $result_rhs };
    }
    else {
	$tbl = { };
    }
    #print Dumper $tbl; print "\n";
    return ($result_lhs, $result_rhs, $tbl);
}

sub rules::expand # recursive
{
    my ($sst, $input_range, $name_stack, $rules, $sub_rules, $col) = @_;
    #print STDERR Dumper $name_stack; print STDERR "\n";
    my $name = $$name_stack[-1];
    #&print_in_col($col, "$name("); &range::print($input_range); print ")\n";
    $gbl_col = $col + 1;
    my $result_lhs_range;
    my $templ_rhs;
    my $result_tbl = {};
    my $tbl;
    my $j = undef;
    foreach my $rule (@$rules) {
	$result_lhs_range = undef; $tbl = undef, $j = 0;
	for (my $i = 0; $i < @{$$rule{'lhs'}}; $i++) {
	    # this resolves infinite iteration
	    if ("@{$$rule{'lhs'}}" eq "@{$$rule{'rhs'}}")
	    { next; }
	    $templ_rhs = $$rule{'rhs'};
	    my $lhs_tkn = $$rule{'lhs'}[$i];
	    my $sub_input_range = [ $$input_range[0] + $j, $$input_range[1] ];
	    my ($result_lhs, $result_rhs) = (undef, []);
	    for (&constraint_name($lhs_tkn)) {
		/^\?recurse$/ and do { # recursion
		    &println_in_col($col, "?recurse");
		    push @$name_stack, $name;
                    my $sub_tbl;
		    ($result_lhs, $result_rhs, $sub_tbl) = &rules::expand($sst, $sub_input_range,
									  $name_stack, $$sub_rules{$$name_stack[-1]}, $sub_rules, $col + 1); # recurse
		    pop @$name_stack;
		    last;
		};
		/^\?wildcard$/ and do {
		    my $next_token = $$rule{'lhs'}[$i + 1];
		    die if !$next_token;
		    my $constraint = &constraint($lhs_tkn);
		    ($result_lhs, $result_rhs, $tbl) = &constraint::expand($name, $lhs_tkn, $constraint, $sst, $sub_input_range, $next_token);
		    #print STDERR &Dumper($result_lhs);
		    #print STDERR &Dumper($result_rhs);
		    #print STDERR &Dumper($tbl);
		    #print STDERR "\n";
		    last;
		};
		/^\?/ and do { # pattern variable
		    if ($$gbl_macros{$lhs_tkn}) { # is the pattern variable a macro
			&println_in_col($col, "calling macro $lhs_tkn from $name");
		    }
		    elsif (&constraint($lhs_tkn)) { # or is the pattern variable a constraint
			my $constraint = &constraint($lhs_tkn);
			($result_lhs, $result_rhs, $tbl) = &constraint::expand($name, $lhs_tkn, $constraint, $sst, $sub_input_range, undef);
		    }
		    else { die; }
		    last;
		};
		# literal token
		($result_lhs, $result_rhs, $tbl) = &constraint::expand($name, undef, \&match, $sst, $sub_input_range, $lhs_tkn);
	    } # for/switch
	    if (!defined $result_lhs) {
		$result_lhs_range = undef;
		$j = 0;
		last;
	    }
	    else {
		if (!defined $result_lhs_range) {
		    $result_lhs_range = $result_lhs;
		}
		elsif ($$result_lhs_range[1] < $$result_lhs[1])	{
		    $$result_lhs_range[1] = $$result_lhs[1];
		}
		$j = $$result_lhs[1] - $$input_range[0] + 1;
		
		my $keys = [keys %$tbl];
		foreach my $key (@$keys) {
		    my $element = $$tbl{$key};
		    $$result_tbl{$key} = $element;
		}
	    }
	} # for ($i)
	if ($result_lhs_range) {
	   last;
	}
    } # foreach $rule
    $gbl_col = $col - 1;
    #if ($result_lhs_range)
    #{ &print_in_col($col, "$name("); &range::print($input_range); print ") = "; &range::println($result_lhs_range); }
    #else 
    #{ &print_in_col($col, "$name("); &range::print($input_range); print ") = undef\n"; }
    #print STDERR Dumper $name_stack; print STDERR "\n";

    return ($result_lhs_range, $templ_rhs, $result_tbl);
}
