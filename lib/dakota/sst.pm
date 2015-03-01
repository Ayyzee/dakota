#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

# Copyright (C) 2007-2015 Robert Nielsen <robert@dakota.org>
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

package dakota::sst;

use strict;
use warnings;

use dakota::util;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
		 sst::changes
		 sst::is_open_token
		 sst::is_close_token
		 sst::make
		 sst::token_seq
		 sst::size
		 sst::at
		 sst::prev_token_str
		 sst::add_token
		 sst::add_comment
		 sst::add_cpp_directive
		 sst::add_leading_ws
		 sst::filestr_no_comments
		 sst::filestr
		 sst::shift_leading_ws
		 sst::dump
		 sst::splice
		 sst_fragment::filestr
		 sst_cursor::make
		 sst_cursor::dump
		 sst_cursor::match_pattern_seq
		 sst_cursor::at
		 sst_cursor::str
		 sst_cursor::size
		 sst_cursor::previous_token
		 sst_cursor::current_token
		 sst_cursor::current_token_p
		 sst_cursor::next_token
		 sst_cursor::token_index
		 sst_cursor::balenced
	      );

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys =  0;
$Data::Dumper::Indent    = 1;	# default = 2

# same code in dakota.pl and parser.pl
my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]?/;
my $wk = qr/[_A-Za-z]$k*[_A-Za-z0-9]*/; # dakota identifier
my $ak = qr/::?$z/;		# absolute scoped dakota identifier
my $rk = qr/$z$ak*/;		# relative scoped dakota identifier
my $d = qr/\d+/;
my $mx = qr/\!|\?/;
my $m  = qr/$z$mx?/;
my $h  = qr|[/._A-Za-z0-9-]|;

# not-escaped " .*? not-escaped "
my $dqstr = qr/(?<!\\)".*?(?<!\\)"/;

# not-escaped ' .*? not-escaped '
my $sqstr = qr/(?<!\\)'.*?(?<!\\)'/;

my $sst_debug = 0;
sub log_sub_name {
  my ($name) = @_;
  #print "$name\n";
}
sub sst::open_token_for_close_token {
  my ($close_token) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  die if (!&sst::is_close_token($close_token));
  my $open_for_close = { ')' => '(',
			 '}' => '{',
			 ']' => '[' };
  my $open_token = $$open_for_close{$close_token};
  #die if (!&sst::is_open_token($open_token));
  return $open_token;
}
sub sst::close_token_for_open_token {
  my ($open_token) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  die if (!&sst::is_open_token($open_token));
  my $close_for_open = { '(' => ')',
			 '{' => '}',
			 '[' => ']' };
  my $close_token = $$close_for_open{$open_token};
  #die if (!&sst::is_open_token($open_token));
  return $close_token;
}
sub sst::is_open_token {
  my ($str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $result = 0;
  if ('(' eq $str ||
      '{' eq $str ||
      '[' eq $str) {
    $result = 1;
  }
  return $result;
}
sub sst::is_close_token {
  my ($str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $result = 0;
  if (')' eq $str ||
      '}' eq $str ||
      ']' eq $str) {
    $result = 1;
  }
  return $result;
}
sub sst::make {
  my ($filestr, $file) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #print STDERR $filestr;
  local $_ = $filestr;

  my $sst = {
	     'prev-line' => 0,
	     'file' => '',
	     'line' => 1,
	     'tokens' => [],
	     'tokens-count' => 0,
	     'leading-ws' => '',
	     'changes' => {},
	    };
  if (defined $file) {
    $$sst{'file'} = $file;
  }
  while (1) {
    if (0) {}
    elsif (m|\G(^ *# *[a-z]+.*?\n)|gcm)   { &sst::add_cpp_directive($sst, $1); }
    elsif (m|\G(\s+)|gc)                  { &sst::add_comment($sst, $1); }
    elsif (m|\G(//.*?\n)|gcs)             { &sst::add_comment($sst, $1); }
    elsif (m|\G(/\*.*?\*/)|gcs)           { &sst::add_comment($sst, $1); }
    elsif (m/\G(include)(\s*)(<$h+>)/gc)  { &sst::add_tokens3($sst, $1, $2, $3); }
    elsif (m/\G(include)(\s*)($dqstr)/gc) { &sst::add_tokens3($sst, $1, $2, $3); }
    elsif (m|\G(\$)($z)($mx)|gc)          { &sst::add_token($sst, "$1$2$3"); }
    elsif (m|\G(\$)($z)|gc)               { &sst::add_token($sst, "$1$2"); }
    elsif (m|\G($z)($mx)|gc)              { &sst::add_token($sst, "$1$2"); }
    elsif (m|\G(\?)($z)(:)($z)|gc)        { &sst::add_token($sst, "$1$2$3$4"); }
    elsif (m|\G(\?)(:)($z)|gc)            { &sst::add_token($sst, "$1$3$2$3"); } # hackhack
    elsif (m|\G(\?)($z)|gc)               { &sst::add_token($sst, "$1$2"); }
    elsif (m|\G($z)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(\d+)|gc)                  { &sst::add_token($sst, $1); }
    elsif (m|\G(=>)|gc)                   { &sst::add_token($sst, $1); } # use: [ 128 ]
    elsif (m|\G(->)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(<<)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(>>)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(::)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(##)|gc)                   { &sst::add_token($sst, $1); }
    elsif (m|\G(#)|gc)                    { &sst::add_token($sst, $1); }
    elsif (m|\G($dqstr)|gc)               { &sst::add_token($sst, $1); }
    elsif (m|\G($sqstr)|gc)               { &sst::add_token($sst, $1); }
    elsif (m|\G(\.\.\.)|gcs)              { &sst::add_token($sst, $1); }
    elsif (m|\G(.)|gcs)                   { &sst::add_token($sst, $1); }
    else                                  { last; }
  }
  my $size = @{$$sst{'tokens'}};
  if (0 != $size) {
    $$sst{'tokens'}[$size - 1]{'trailing-ws'} = $$sst{'leading-ws'};
  }
  delete $$sst{'leading-ws'};
  delete $$sst{'line'};
  delete $$sst{'prev-line'};
  #print STDERR &Dumper($sst);
  return $sst;
}
sub sst::changes {
  my ($sst) = @_;
  return $$sst{'changes'};
}
sub sst::line {
  my ($sst, $index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $index_w_line = $index;

  while (! $$sst{'tokens'}[$index_w_line]{'line'}) {
    if (0 eq $index_w_line) {
      last;
    }
  }
  my $line = $$sst{'tokens'}[$index_w_line]{'line'};
  return $line;
}
sub sst::token_seq {
  my ($sst, $start_index, $end_index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $token_seq = [@{$$sst{'tokens'}}[$start_index..$end_index]];
  return $token_seq;
}
sub sst::size {
  my ($sst) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $size = @{$$sst{'tokens'}};
  return $size;
}
sub sst::at {
  my ($sst, $index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #my $size = &sst::size($sst);
  #my $file = $$sst{'file'};
  #print "$file:  $__sub__(size=$size, index=$index)\n";
  #if (0 > $index || $index + 1 > $size)
  #{
  #die "sst::at($index) where sst::size() = $size\n";
  #}
  return $$sst{'tokens'}[$index]{'str'};
}
sub sst::prev_token_str {
  my ($sst) = @_;		#my $__sub__ = (caller(0))[3];
  my $token = $$sst{'tokens'}[-1];
  return $$token{'str'};
}
sub sst::add_tokens3 {
  my ($sst, $str1, $str2, $str3) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  &sst::add_token($sst, $str1);
  &sst::add_token($sst, $str2);
  &sst::add_token($sst, $str3);
}
sub sst::add_tokens2 {
  my ($sst, $str1, $str2) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  &sst::add_token($sst, $str1);
  &sst::add_token($sst, $str2);
}
sub sst::add_token {
  my ($sst, $str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if ($str =~ m/^\s+$/gs) {
    &sst::add_leading_ws($sst, $str);
    return;
  }
  $$sst{'line'} += ($str =~ tr/\n/\n/);
  my $token = { 'str' => $str };
  if ($$sst{'line'} != $$sst{'prev-line'}) {
    $$sst{'prev-line'} = $$token{'line'} = $$sst{'line'};
  }
  if (0 == $$sst{'tokens-count'}) {
    if ($sst_debug) {
      print STDERR "$str\n";
    }
    $$token{'begin-word'} = 1;
  } else {
    if (';' eq &sst::prev_token_str($sst) ||
	'{' eq &sst::prev_token_str($sst) ||
	'}' eq &sst::prev_token_str($sst)) {
      if ($str =~ m|$z|) {
	if ($sst_debug) {
	  print STDERR "$str\n";
	}
	$$token{'begin-word'} = 1;
      } elsif ($sst_debug) {
	print STDERR "  $str\n";
      }
    } elsif ($sst_debug) {
      print STDERR "  $str\n";
    }
  }
  if ('' ne $$sst{'leading-ws'}) {
    $$token{'leading-ws'} = $$sst{'leading-ws'};
    $$sst{'leading-ws'} = '';
  }
  push @{$$sst{'tokens'}}, $token;
  $$sst{'tokens-count'} = scalar @{$$sst{'tokens'}};
}
sub sst::add_comment {
  my ($sst, $str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #print STDERR "comment=<$str>\n";
  &sst::add_leading_ws($sst, $str);
}
sub sst::add_cpp_directive {
  my ($sst, $str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  &sst::add_leading_ws($sst, $str);
}
sub sst::add_leading_ws {
  my ($sst, $str) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  $$sst{'line'} += ($str =~ tr/\n/\n/);
  $$sst{'leading-ws'} .= $str;

  if ($sst_debug) {
    while ($$sst{'leading-ws'} =~ s|\n|\\n|g) {
    }
    while ($$sst{'leading-ws'} =~ s| |\\s|g) {
    }
  }
}
sub sst::filestr_no_comments {
  my ($sst) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $filestr = '';
  foreach my $token (@{$$sst{'tokens'}}) {
    if ($$token{'leading-ws'}) {
      while ($$token{'leading-ws'} =~ s|[^\s]||gs) {
      }
      $filestr .= $$token{'leading-ws'};
    }
    $filestr .= $$token{'str'};
  }
  while ($$sst{'leading-ws'} =~ s|[^\s]||gs) {
  }
  $filestr .= $$sst{'leading-ws'};
  return $filestr;
}
sub sst::filestr {
  my ($sst) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $filestr = '';

  foreach my $token (@{$$sst{'tokens'}}) {
    if ($$token{'leading-ws'}) {
      $filestr .= $$token{'leading-ws'};
    }
    $filestr .= $$token{'str'};
  }
  if ($$sst{'leading-ws'}) {
    $filestr .= $$sst{'leading-ws'};
  }
  return $filestr;
}
sub sst::shift_leading_ws {
  my ($sst, $index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if (0 < $index && $$sst{'tokens'}[$index]{'leading-ws'}) {
    if (!exists $$sst{'tokens'}[$index - 1]{'trailing-ws'}) {
      $$sst{'tokens'}[$index - 1]{'trailing-ws'} = '';
    }

    $$sst{'tokens'}[$index - 1]{'trailing-ws'} .= $$sst{'tokens'}[$index]{'leading-ws'};
    delete $$sst{'tokens'}[$index]{'leading-ws'};
  }
}
sub sst::dump {
  my ($sst, $begin_index, $end_index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  my $delim = '';
  my $str = '';

  for (my $i = $begin_index; $i <= $end_index; $i++) {
    my $tkn .= &sst::at($sst, $i);
    $str .= $delim;
    $str .= "'$tkn'";
    $delim = ',';
  }
  return "\[$str\]";
}
sub sst::_process_ws_first {
  my ($sst, $index, $length, $seq) = @_;
  my $empty_rhs_ws = '';
  if (0 == scalar @$seq) {
    for (my $i = $index; $i < $index + $length; $i++) {
      $empty_rhs_ws .= $$sst{'tokens'}[$i]{'leading-ws'}  ||= '';
      $empty_rhs_ws .= $$sst{'tokens'}[$i]{'trailing-ws'} ||= '';
    }
  }
  return $empty_rhs_ws;
}
sub sst::_process_ws_last {
  my ($sst, $index, $length, $seq, $empty_rhs_ws) = @_;
  if (0 == scalar @$seq) {
    if ($index < scalar @{$$sst{'tokens'}}) {
      my $leading_ws = $$sst{'tokens'}[$index]{'leading-ws'};
      $$sst{'tokens'}[$index]{'leading-ws'} = $empty_rhs_ws . $leading_ws;
    } else {
      die;
    }
  }
}
sub sst::_process_ws {
  my ($sst, $index, $length, $seq) = @_;
  # [ tkn1 tkn2 tkn3 ] => [                     ] # empty rhs
  # [ tkn1 tkn2 tkn3 ] => [ tkn3 tkn2 tkn1      ] # lhs == rhs
  # [ tkn1 tkn2 tkn3 ] => [ tkn1 tkn2 tkn3 tkn4 ] # lhs < rhs
  # [ tkn1 tkn2 tkn3 ] => [ tkn1 tkn2           ] # lhs > rhs

  # [ tkn1 tkn2 tkn3 ] => [ tkn1 tkn2      ]
  # [ tkn1 tkn2 tkn3 ] => [      tkn2 tkn3 ]
  # [ tkn1 tkn2 tkn3 ] => [ tkn1      tkn3 ]

  my $new_seq = [];
  for (my $i = 0; $i < @$seq; $i++) {
    my $lhs_token;
    if ($i < $length) {
      %$lhs_token = %{$$sst{'tokens'}[$index + $i]}; # copy
    } else {
      $lhs_token = { 'str' => undef };
    }
    $$lhs_token{'str'} = $$seq[$i]{'str'};
    &_add_last($new_seq, $lhs_token);
  }
  return $new_seq;
}
sub sst::splice {
  my ($sst, $index, $lhs_num_tokens, $rhs) = @_;
  my $empty_rhs_ws = &sst::_process_ws_first($sst, $index, $lhs_num_tokens, $rhs);
  my $new_rhs = &sst::_process_ws($sst, $index, $lhs_num_tokens, $rhs);
  my $new_rhs_num_tokens = scalar @$new_rhs;
  splice @{$$sst{'tokens'}}, $index, $lhs_num_tokens, @$new_rhs;
  &sst::_process_ws_last($sst, $index, $lhs_num_tokens, $rhs, $empty_rhs_ws);
  return $new_rhs_num_tokens;
}
sub sst_fragment::filestr {
  my ($sst_fragment) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $prev_was_ident = 0;
  my $filestr = '';
  foreach my $token (@$sst_fragment) {
    my $is_ident = 0;
    if ($$token{'str'} =~ m/^$z$/) {
      $is_ident = 1;
    }

    if ($$token{'leading-ws'}) {
      $filestr .= $$token{'leading-ws'};
    } elsif ($prev_was_ident && $is_ident) {
      $filestr .= ' ';
    }

    $filestr .= $$token{'str'};

    if ($$token{'trailing-ws'}) {
      $prev_was_ident = 0;
      $filestr .= $$token{'trailing-ws'};
    } else {
      $prev_was_ident = $is_ident;
    }
  }
  if ("\n" ne substr $filestr, -1) { # add trailing newline if missing
    print STDERR "Warning: Adding missing final newline\n";
    $filestr .= "\n";
  }
  return $filestr;
}
# take 1 or 2 or 3 args
sub sst_cursor::make {
  my ($sst, $first_token_index, $last_token_index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $sst_cursor = { 'sst' => $sst };
  $$sst_cursor{'current-token-index'} = 0;

  if (defined $first_token_index) {
    $$sst_cursor{'first-token-index'} = $first_token_index;
  }
  if (defined $last_token_index) {
    $$sst_cursor{'last-token-index'} =  $last_token_index;
  }
  return $sst_cursor;
}
sub sst_cursor::dump {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $sst_tokens = $$sst_cursor{'sst'}{'tokens'};
  delete $$sst_cursor{'sst'}{'tokens'};

  my $sst_leading_ws = $$sst_cursor{'sst'}{'leading-ws'};
  delete $$sst_cursor{'sst'}{'leading-ws'};

  print STDERR &Dumper($sst_cursor);

  $$sst_cursor{'sst'}{'tokens'} = $sst_tokens;
  $$sst_cursor{'sst'}{'leading-ws'} = $sst_leading_ws;
  return $sst_cursor;
}
sub constraint_literal_dquoted_cstring {
  my ($sst, $range) = @_;
  my ($result_lhs, $result_rhs) = (undef, []);
  my $token = &sst::at($sst, $$range[0]);

  if ($token =~ m/\$$dqstr/) {
    $result_lhs = [ $$range[0], $$range[0] ];
    push @$result_rhs, $token;
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_literal_squoted_cstring {
  my ($sst, $range) = @_;
  my ($result_lhs, $result_rhs) = (undef, []);
  my $token = &sst::at($sst, $$range[0]);

  if ($token =~ m/\$$sqstr/) {
    $result_lhs = [ $$range[0], $$range[0] ];
    push @$result_rhs, $token;
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_ident {
  my ($sst, $range) = @_;
  my ($result_lhs, $result_rhs) = (undef, []);
  my $token = &sst::at($sst, $$range[0]);

  if ($token =~ m/$z/) {
    $result_lhs = [ $$range[0], $$range[0] ];
    push @$result_rhs, $token;
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_method_name {
  my ($sst, $range) = @_;
  my ($result_lhs, $result_rhs) = (undef, []);
  my $token = &sst::at($sst, $$range[0]);

  if ($token =~ m/$m/) {
    $result_lhs = [ $$range[0], $$range[0] ];
    push @$result_rhs, $token;
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_block {
  my ($sst, $range) = @_;
  return &constraint_balenced($sst, $range);
}
sub constraint_list {
  my ($sst, $range) = @_;
  return &constraint_balenced($sst, $range);
}
sub constraint_block_in {
  my ($sst, $range) = @_;
  return &constraint_balenced_in($sst, $range);
}
sub constraint_list_in {
  my ($sst, $range) = @_;
  return &constraint_balenced_in($sst, $range);
}
sub constraint_balenced {
  my ($sst, $range) = @_;
  my $first_token = $$sst{'tokens'}[$$range[0]]{'str'};
  #print STDERR "first_token_index: $$range[0]\n";
  #print STDERR "first_token: $first_token\n";
  my ($result_lhs, $result_rhs) = (undef, []);

  my $close_token_index = $$range[0];
  my $opens = [];

  if (&sst::is_open_token($first_token)) {
    while ($close_token_index <= $$range[1]) {
      my $token = &sst::at($sst, $close_token_index);

      if (&sst::is_open_token($token)) {
	push @$opens, $token;
      } elsif (&sst::is_close_token($token)) {
	my $open_token = pop @$opens;

	if (!defined $open_token) {
	  return undef;
	}

	die if $open_token ne &sst::open_token_for_close_token($token);
      }
      push @$result_rhs, $token;

      if (0 == @$opens) {
	$result_lhs = [ $$range[0], $close_token_index ];
	last;
      }
      $close_token_index++;
    }
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_balenced_in {
  my ($sst, $range) = @_;
  my ($result_lhs, $result_rhs) = (undef, []);

  if (1 <= $$range[0]) {
    ($result_lhs, $result_rhs) = &constraint_balenced($sst, [ $$range[0] - 1, $$range[1] ]);

    if ($result_lhs) {
      $$result_lhs[1]--;
      die if 0 == $$result_lhs[1];

      for (my $i = $$result_lhs[0]; $i < $$result_lhs[1]; $i++) {
	my $token = &sst::at($sst, $i);
	push @$result_rhs, $token;
      }
    }
  }
  return ($result_lhs, $result_rhs);
}
sub constraint_for_name {
  my ($name) = @_;
  my $constraint_tbl = {
			'?method-name' => \&constraint_method_name,
			'?literal-dquoted-cstring' => \&constraint_literal_dquoted_cstring,
			'?literal-squoted-cstring' => \&constraint_literal_squoted_cstring,
			'?ident' => \&constraint_ident,
			'?block' => \&constraint_block,
		       };
  my $constraint = $$constraint_tbl{$name};
  return $constraint;
}

# really should return -1, 0, 1
# but were not using it for sorting (yet)
sub sst_cursor::match_pattern_seq {
  my ($sst_cursor, $pattern_seq) = @_;
  my $range = undef;
  my $matches = undef;
  my $input_len = &sst_cursor::size($sst_cursor);
  my $pattern_seq_len = @$pattern_seq;

  if ($input_len >= $pattern_seq_len) {
    my $all_index = [];
    $range = [];
    $matches = {};
    for (my $i = 0; $i < $pattern_seq_len; $i++) {
      my $input_token = &sst_cursor::at($sst_cursor, $i);
      my $pattern_token = $$pattern_seq[$i];

      if (!defined $input_token || !defined $pattern_token) {
	$range = undef;
	$matches = undef;
	last;
      }
      #print STDERR "$input_token  <=>  $pattern_token\n";

      if ($pattern_token =~ m/^\?/) {
	my $constraint = &constraint_for_name($pattern_token);
	my ($result_lhs, $result_rhs) = &$constraint($$sst_cursor{'sst'},
						     [ $$sst_cursor{'first-token-index'} + $i,
						       @{$$sst_cursor{'sst'}{'tokens'}} - 1 ]);
	if ($result_lhs) {
	  $range = $result_lhs;
	  $$matches{$pattern_token} = $result_rhs;
	  &dakota::util::_add_last($all_index, $$result_lhs[0]);
	  &dakota::util::_add_last($all_index, $$result_lhs[1]);
	} else {
	  $all_index = [];
	  $range = undef;
	  $matches = undef;
	  last;
	}
      } else {
	if ($input_token eq $pattern_token) {
	  $range = [ $$sst_cursor{'first-token-index'} + $i,
		     $$sst_cursor{'first-token-index'} + $i ];

	  &dakota::util::_add_last($all_index, $$sst_cursor{'first-token-index'} + $i);
	} else {
	  $all_index = [];
	  $range = undef;
	  $matches = undef;
	  last;
	}
      }
    }
    if ($range && 0 != @$range) {
      my $sorted_all_index = [sort {$a <=> $b} @$all_index];
      my $first_token_index = &dakota::util::_first($sorted_all_index);
      my $last_token_index = &dakota::util::_last($sorted_all_index);
      my $from_index = 0;
      my $to_index = $from_index + $last_token_index - $first_token_index;
      $range = [ $from_index, $to_index ];
    }
  }
  return ($range, $matches);
}
sub sst_cursor::str {
  my ($sst_cursor, $range) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if (!defined $range) {
    $range = [0, @{$$sst_cursor{'sst'}} - 1];
  }
  my $str = '';

  for (my $i = $$range[0]; $i <= $$range[1]; $i++) {
    my $token = &sst_cursor::at($sst_cursor, $i);
    $str .= $token;
  }
  return $str;
}
sub sst_cursor::at {
  my ($sst_cursor, $index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #my $size = @{$$sst_cursor{'sst'}{'tokens'}};
  #my $file = $$sst_cursor{'sst'}{'file'};
  #print "$file:  $__sub__(size=$size, index=$index)\n";

  #die if ($size <= $index);

  if (exists $$sst_cursor{'first-token-index'}) {
    $index += $$sst_cursor{'first-token-index'};
  }
  if (exists $$sst_cursor{'last-token-index'}) {
    if ($index > $$sst_cursor{'last-token-index'}) {
      print STDERR "index $index larger than last-token-index $$sst_cursor{'last-token-index'}\n";
    }
  }
  return &sst::at($$sst_cursor{'sst'}, $index);
}
sub sst_cursor::size {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  my $size;
  if ($$sst_cursor{'last-token-index'}) {
    $size = $$sst_cursor{'last-token-index'} + 1;
  } else {
    $size = @{$$sst_cursor{'sst'}{'tokens'}};
  }

  if (exists $$sst_cursor{'first-token-index'}) {
    $size -= $$sst_cursor{'first-token-index'};
  }
  return $size;
}
sub sst_cursor::previous_token {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  return &sst::at($$sst_cursor{'sst'}, $$sst_cursor{'current-token-index'} - 1);
}
sub sst_cursor::current_token_p {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  if ($$sst_cursor{'current-token-index'} < @{$$sst_cursor{'sst'}{'tokens'}}) {
    return 1;
  } else {
    return 0;
  }
}
sub sst_cursor::current_token {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  return &sst::at($$sst_cursor{'sst'}, $$sst_cursor{'current-token-index'});
}
sub sst_cursor::next_token {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  return &sst::at($$sst_cursor{'sst'}, $$sst_cursor{'current-token-index'} + 1);
}
sub sst_cursor::balenced {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  my $index = $$sst_cursor{'current-token-index'};
  while (!&sst::is_open_token(&sst::at($$sst_cursor{'sst'}, $index))) {
    $index++;
  }
  my $stk = [];
  for (my $i = $index;
       $i < &sst::size($$sst_cursor{'sst'});
       $i++) {
    my $token = &sst::at($$sst_cursor{'sst'}, $i);
    if (&sst::is_open_token($token)) {
      my $expected_close_token = &sst::close_token_for_open_token($token);
      push @$stk, $expected_close_token;
    } elsif (&sst::is_close_token($token)) {
      my $expected_close_token = pop @$stk;

      if ($expected_close_token ne $token) {
	print STDERR "error: expected $expected_close_token but got $token\n"; die;
      }

      if (0 == @$stk) {
	return ($index, $i);
      }
    }
  }
  print STDERR "error: unbalenced\n"; die;
}
sub sst_cursor::logger {
  my ($sst_cursor, $file, $line) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $current_token = &sst_cursor::current_token($sst_cursor);
  if (defined $current_token) {
    print STDERR $file, ":", $line, ": ", $current_token, "\n";
  }
}
sub sst_cursor::token_index {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $token_index = $$sst_cursor{'current-token-index'};
  if (exists $$sst_cursor{'first-token-index'}) {
    $token_index -= $$sst_cursor{'first-token-index'};
  }
  return $token_index;
}
sub sst_cursor::match {
  my ($sst_cursor, $match_token) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if (&sst_cursor::current_token($sst_cursor) eq $match_token) {
    $$sst_cursor{'current-token-index'}++;
  } else {
    &sst_cursor::error($sst_cursor);
  }
  return $match_token;
}
sub sst_cursor::match_any {
  my ($sst_cursor) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  my $token = &sst_cursor::current_token($sst_cursor);
  $$sst_cursor{'current-token-index'}++;
  return $token;
}
sub sst_cursor::match_re {
  my ($sst_cursor, $match_token) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if (&sst_cursor::current_token($sst_cursor) =~ /$match_token/) {
    $$sst_cursor{'current-token-index'}++;
  } else {
    &sst_cursor::error($sst_cursor);
  }
  return &sst::at($$sst_cursor{'sst'}, $$sst_cursor{'current-token-index'} - 1);
}
sub sst_cursor::warning {
  my ($sst_cursor, $token_index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);

  if (!defined $token_index) {
    $token_index = $$sst_cursor{'current-token-index'};
  }
  my $sst = $$sst_cursor{'sst'};
  my $line = &sst::line($sst, $token_index);

  printf STDERR "%s:%i: did not expect \'%s\'\n",
    $$sst{'file'} ||= "<unknown>",
      $line,
	&sst::at($sst, $token_index);
  return;
}
sub sst_cursor::error {
  my ($sst_cursor, $token_index) = @_;
  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  &sst_cursor::warning($sst_cursor, $token_index);
  exit 1;
}

1;
