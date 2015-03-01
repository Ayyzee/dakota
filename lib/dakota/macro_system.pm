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

package dakota::macro_system;

my $gbl_prefix;

sub prefix {
  my ($path) = @_;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    &prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!\n";
  }
}

BEGIN {
  $gbl_prefix = &prefix($0);
  unshift @INC, "$gbl_prefix/lib";
};

use strict;
use warnings;

use dakota::sst;
use dakota::dakota;
use dakota::util;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 0;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 0;   # default = 2

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

our @ISA = qw(Exporter);
our @EXPORT= qw(
                 macro_expand
             );

my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]/;
my $zt = qr/$z-t/;
# not-escaped " .*? not-escaped "
my $dqstr = qr/(?<!\\)".*?(?<!\\)"/;
#my $dqstr = qr/"(?:[^"\\]++|\\.)*+"/; # from the web

my $constraints = {
  'balenced' =>         \&balenced,
  'balenced-in' =>      \&balenced_in,
  'block' =>            \&block,
  'block-in' =>         \&block_in,
  'dquote-str' =>       \&dquote_str,
  'ident' =>            \&ident,
  'kw-args-ident-1' =>       \&kw_args_ident_1,
  'kw-args-ident-2' =>       \&kw_args_ident_2,
  'kw-args-ident-3' =>       \&kw_args_ident_3,
  'kw-args-ident-4' =>       \&kw_args_ident_4,
  'list' =>             \&list,
  'list-in' =>          \&list_in,
  'list-member-term' => \&list_member_term, # move to a language specific macro
  'list-member' =>      \&list_member,
  'symbol' =>           \&symbol,
  'type' =>             \&type,
  'type-ident' =>       \&type_ident,
  'visibility' =>       \&visibility, # move to a language specific macro
};

my $debug;
my $gbl_match_count = 0;

### start of constraint variable defns
sub list_member_term  { # move to a language specific macro
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($$user_data{'list'}{'member'}{'term'}{$tkn}) {
    $result = $index;
  }
  return $result;
}
sub list_member {
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
    } elsif ($$user_data{'list'}{'close'} eq $tkn && $is_framed) {
      $is_framed--;
    }
    $o++;
  }
  return -1;
}
sub visibility { # move to a language specific macro
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($$user_data{'visibility'}{$tkn}) {
    $result = $index;
  }
  return $result;
}
sub ident {
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($tkn =~ /^$k+$/ && (-1 == &type_ident($sst, $index, $constraint, $user_data))) { # should be removed
    $result = $index;
  }
  return $result;
}
sub type_ident {
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($tkn =~ /^$zt$/) { # bugbug: requires ab-t at a min (won't allow single char before -t)
    $result = $index;
  }
  return $result;
}
sub kw_args_ident_1 {
  my ($sst, $index, $constraint, $user_data) = @_;
  return &kw_args_ident_common($sst, $index, $constraint, $user_data, 1);
}
sub kw_args_ident_2 {
  my ($sst, $index, $constraint, $user_data) = @_;
  return &kw_args_ident_common($sst, $index, $constraint, $user_data, 2);
}
sub kw_args_ident_3 {
  my ($sst, $index, $constraint, $user_data) = @_;
  return &kw_args_ident_common($sst, $index, $constraint, $user_data, 3);
}
sub kw_args_ident_4 {
  my ($sst, $index, $constraint, $user_data) = @_;
  return &kw_args_ident_common($sst, $index, $constraint, $user_data, 4);
}
sub kw_args_ident_common {
  my ($sst, $index, $constraint, $user_data, $num_fixed_args) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if (exists $$user_data{'kw-args-ident'}{$tkn}) {
    if ($$user_data{'kw-args-ident'}{$tkn} == $num_fixed_args) {
      $result = $index;
    }
  }
  return $result;
}
# this is very incomplete
sub type {
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
sub symbol {
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($tkn =~ /^\$$z(\!|\?)?$/) { # bugbug: requires ab at a min (won't allow single char)
    $result = $index;
  }
  return $result;
}
sub dquote_str {
  my ($sst, $index, $constraint, $user_data) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($tkn =~ /^$dqstr$/) {
    $result = $index;
  }
  return $result;
}
sub block { # body is optional since it uses balenced()
  my ($sst, $open_token_index, $constraint, $user_data) = @_;
  return &balenced($sst, $open_token_index, $constraint, $user_data);
}
sub list { # body is optional since it uses balenced()
  my ($sst, $open_token_index, $constraint, $user_data) = @_;
  return &balenced($sst, $open_token_index, $constraint, $user_data);
}
sub block_in { # body is optional since it uses balenced_in() which uses balenced()
  my ($sst, $index, $constraint, $user_data) = @_;
  return &balenced_in($sst, $index, $constraint, $user_data);
}
sub list_in { # body is optional since it uses balenced_in() which uses balenced()
  my ($sst, $index, $constraint, $user_data) = @_;
  return &balenced_in($sst, $index, $constraint, $user_data);
}
sub balenced {
  my ($sst, $open_token_index, $user_data) = @_;
  my $close_token_index = $open_token_index;
  my $opens = [];
  my $result = -1;

  while (1) {
    my $open_token;
    my $close_token;
    if (&sst::is_open_token($open_token = &sst::at($sst, $close_token_index))) {
      push @$opens, $open_token;
    } elsif (&sst::is_close_token($close_token = &sst::at($sst, $close_token_index))) {
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
sub balenced_in {
  my ($sst, $index, $constraint, $user_data) = @_;
  die if 0 == $index;
  my $result = &balenced($sst, $index - 1, $constraint, $user_data);
  if (-1 != $result) {
    $result--;
  }
  return $result;
}
sub assert {
  my ($result) = @_;
  die if $result != 0;
}
### end of constraint variable defns
sub macro_expand_recursive {
  my ($sst, $i, $macros, $macro_name, $macro, $expanded_macro_names, $user_data) = @_;
  my $change_count = 0;

  foreach my $depend_macro_name (@{$$macro{'before'}}) {
    if (!exists($$expanded_macro_names{$depend_macro_name})) {
      $change_count += &macro_expand_recursive($sst, $i, $macros, $depend_macro_name, $$macros{$depend_macro_name},
                                               $expanded_macro_names, $user_data);
      $$expanded_macro_names{$depend_macro_name} = 1;
    }
  }
  my $num_tokens = scalar @{$$sst{'tokens'}};
  for (my $r = 0; $r < scalar @{$$macro{'rules'}}; $r++) {
    my $rule = $$macro{'rules'}[$r];
    last if $i > $num_tokens - @{$$rule{'pattern'}};

    my ($last_index, $lhs, $rhs_for_pattern)
      = &rule_match($sst, $i, $$rule{'pattern'}, $user_data, $macros, $macro_name, $macro);

    if (-1 != $last_index) {
      my ($common_num_tokens, $lhs_num_tokens, $rhs_num_tokens)
        = &rule_replace($sst, $i, $last_index, $$rule{'template'}, $rhs_for_pattern, $lhs, $macro_name);

      if ($lhs_num_tokens > $common_num_tokens) {
        if (!defined $$sst{'changes'}{'macros'}{$macro_name}{$r}) {
          $$sst{'changes'}{'macros'}{$macro_name}{$r} = 0;
        }
        $$sst{'changes'}{'macros'}{$macro_name}{$r}++;

        $change_count++;
        last;
      }
    }
  }
  return $change_count;
}
sub macros_expand_index {
  my ($sst, $i, $macros, $user_data) = @_;
  my $change_count = 0;

  foreach my $macro_name (sort keys %$macros) {
    if ($change_count = &macro_expand_recursive($sst, $i, $macros, $macro_name, $$macros{$macro_name}, {}, $user_data)) {
      last;
    }
  }
  return $change_count;
}
sub macros_expand {
  my ($sst, $macros, $user_data) = @_;

  if ($debug) {
    print STDERR "[\n";
  }
  for (my $i = 0; $i < @{$$sst{'tokens'}}; $i++) {
    while (&macros_expand_index($sst, $i, $macros, $user_data)) {
      # nothing
    }
  }
  if ($debug) {
    print STDERR "],\n";
  }
}
sub xhs_dump {
  my ($rhs) = @_;
  my $delim1 = '';
  my $delim2 = '';
  my $str = '';
  $str .= '[';

  foreach my $seq (@$rhs) {
    $delim2 = '';
    $str .= $delim1 . '[';
    $delim1 = ',';
    foreach my $tkn (@$seq) {
      $str .= $delim2 . "'" . $$tkn{'str'} . "'";
      $delim2 = ',';
    }
    $str .= ']';
  }
  $str .= ']';
  return $str;
}
sub debug_str_match {
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

    foreach my $m (@$match) {
      push @$match_tokens, $$m{'str'};
    }

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
sub debug_print_match {
  my ($macro_name, $str2, $str3, $i, $last_index, $pattern, $sst, $lhs) = @_;
  if ($debug >= 2 || $last_index != -1 && $debug >= 1) {
    print STDERR
      " {\n" .
      "  'macro' =>          '$macro_name',\n";

    if (2 <= $debug && ('' ne $str2 || '' ne $str3)) {
      print STDERR
        "  'details' =>\n" .
        "  \[\n" .
        $str2;
      if (3 <= $debug) {
        print STDERR $str3;
      }
      print STDERR "  \],\n";
    }
    print STDERR
      "  'range' =>          " . &Dumper([$i, $last_index]) . ",\n" .
      "  'pattern' =>        " . &Dumper($pattern) . ",\n" .
      "  'lhs' =>            " . &xhs_dump($lhs) . ",\n";

    if (-1 == $last_index) {
      print STDERR " },\n";
    }
  }
}
sub debug_print_replace {
  my ($template, $rhs, $lhs_num_tokens) = @_;
  if ($debug) {
    my $rhs_num_tokens = scalar @$rhs;
    print STDERR
      "  'template' =>       " . &Dumper($template) . ",\n" .
      "  'rhs' =>            " . &xhs_dump($rhs) . ",\n" .
      "  'lhs-num-tokens' => $lhs_num_tokens" . ",\n" .
      "  'rhs-num-tokens' => $rhs_num_tokens" . ",\n" .
      " },\n";
  }
}
sub literal { # not a constraint
  my ($sst, $index, $literal) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;

  if ($tkn eq $literal) {
    $result = $index;
  }
  return $result;
}
sub regex { # not a constraint
  my ($sst, $index, $regex) = @_;
  my $tkn = &sst::at($sst, $index);
  my $result = -1;
  my $re_match;

  if ($tkn =~ $regex) {
    $result = $index;
    $re_match = $1;
  }
  return ($result, $re_match);
}
sub rhs_from_template {
  my ($template, $lhs, $rhs_for_pattern) = @_;
  my $rhs = [];
  foreach my $tkn (@$template) {
    die if !$tkn;
    my $tkns;

    if ($tkn =~ /^\?(\d+)$/) {
      die if 0 == $1; # ?0 should return entire match
      my $j = $1 - 1;
      $tkns = $$lhs[$j];
    } else {
      $tkns = $$rhs_for_pattern{$tkn};
      if (!$tkns) { # these are tokens that exists only in the template/rhs and not in the pattern/lhs
        $tkns = [ { 'str' => $tkn } ];
      }
    }
    push @$rhs, $tkns;
  }
  return $rhs
}
sub rule_match {
  my ($sst, $i, $pattern, $user_data, $macros, $macro_name, $macro) = @_;
  $gbl_match_count++;
  my $debug2_str = '';
  my $debug3_str = '';

  my $prev_last_index = $i;
  my ($last_index, $rhs_for_pattern, $lhs) = ($i, {}, []);

  for (my $j = 0; $j < @$pattern; $j++) {
    my $match;
    my $constraint_name;

    SWITCH: {
      ($$pattern[$j] =~ /^\?\/(.+)\/$/) && do { # ?/some-regex/
        my $re_str = $1;
        # match by regex
        my $re_match;
        ($last_index, $re_match) = &regex($sst, $prev_last_index, qr/$re_str/); # regex() is not a constraint
        $match = [ { 'str' => $re_match } ];
        last SWITCH;
      };
      ($$pattern[$j] =~ /^\?($k+)$/) && do { # ?some-ident
        my $pattern_name = $1;
        # 0: look for aux-rule pattern
        my $aux_rule = $$macro{'aux-rules'}{$pattern_name};

        # 1: look for other macro with name
        my $m = $$macros{$pattern_name};
        # match by other macro rhs

        # 2: look for constraint
        my $constraint = $$constraints{$pattern_name};
        if (!defined $constraint) {
          die "Could not find implementation for constraint $pattern_name";
        }
        # match by constraint
        $last_index = &$constraint($sst, $prev_last_index, $pattern_name, $user_data);
        $match = [ @{$$sst{'tokens'}}[$prev_last_index..$last_index] ];
        $constraint_name = $pattern_name;
        last SWITCH;
      };
      ($$pattern[$j] =~ /^[^?].*$/) && do { # anything not begining with ?
        # match by literal
        $last_index = &literal($sst, $prev_last_index, $$pattern[$j]); # literal() is not a constraint
        $match = [ { 'str' => "$$sst{'tokens'}[$last_index]{'str'}" } ];
        $constraint_name = undef;
        last SWITCH;
      };
      #else
      die "unexpected pattern $$pattern[$j]\n";
    }
    if (-1 != $last_index) {
      $$rhs_for_pattern{$$pattern[$j]} = $match;
      push @$lhs, $match;
      if (2 <= $debug) {
        $debug2_str .= &debug_str_match($i, $j, $last_index, $match, $constraint_name);
      }
      $prev_last_index = $last_index + 1;
    } else {
      if (3 <= $debug) {
        $debug3_str .= &debug_str_match($i, $j, $last_index, undef, $constraint_name);
      }
      last;
    }
  }
  &debug_print_match($macro_name, $debug2_str, $debug3_str, $i, $last_index, $pattern, $sst, $lhs);
  return ($last_index, $lhs, $rhs_for_pattern);
}
sub rule_replace {
  my ($sst, $i, $last_index, $template, $rhs_for_pattern, $lhs, $macro_name) = @_;
  my $rhs = &rhs_from_template($template, $lhs, $rhs_for_pattern);
  &sst::shift_leading_ws($sst, $i);
  if (0) {
    print STDERR "LHS: " . &Dumper($lhs) . "\n";
    print STDERR "RHS: " . &Dumper($rhs) . "\n";
    print STDERR "lhs: " . &Dumper(&flatten($lhs)) . "\n";
    print STDERR "rhs: " . &Dumper(&flatten($rhs)) . "\n";
  }
  my $lhs_num_tokens = $last_index - $i + 1;
  &assert($lhs_num_tokens - scalar @{&dakota::util::flatten($lhs)});
  &debug_print_replace($template, $rhs, $lhs_num_tokens);
  my $flat_rhs = &dakota::util::flatten($rhs);
  my $_rhs_num_tokens = scalar @$flat_rhs;
  my $common_num_tokens = 0;
  my $min_num_tokens = &dakota::util::min($lhs_num_tokens, $_rhs_num_tokens);

  for (my $k = 0; $k < $min_num_tokens; $k++) {
    ## if $$lhs[$k] eq $$rhs[$k]
    if ($$sst{'tokens'}[$i + $k]{'str'} eq $$flat_rhs[$k]{'str'}) {
      $common_num_tokens++;
    } else {
      last;
    }
  }
  if (1) {
  if ($lhs_num_tokens == $common_num_tokens && $common_num_tokens < $_rhs_num_tokens) {
    die "ERROR: infinite loop: macro $macro_name\n";
  }
  if ($lhs_num_tokens == $common_num_tokens && $common_num_tokens == $_rhs_num_tokens) {
    # the pattern and the template yeild are exactly the same
    # it would create an infinite loop
    return ($common_num_tokens, $lhs_num_tokens, $_rhs_num_tokens);
  }
  if (0 < $common_num_tokens ) {
    # adjust the slice smaller here
  }
  }
  my $rhs_num_tokens = &sst::splice($sst, $i, $lhs_num_tokens, $flat_rhs);
  assert($_rhs_num_tokens - $rhs_num_tokens);
  return ($common_num_tokens, $lhs_num_tokens, $rhs_num_tokens);
}
sub lang_user_data {
  my $user_data;
  if ($ENV{'DK_LANG_USER_DATA_PATH'}) {
    my $path = $ENV{'DK_LANG_USER_DATA_PATH'};
    $user_data = do $path or die "do $path failed: $!\n";
  } elsif ($gbl_prefix) {
    my $path = "$gbl_prefix/src/dakota-lang-user-data.pl";
    $user_data = do $path or die "do $path failed: $!\n";
  } else {
    die;
  }
  return $user_data;
}

unless (caller) {
  my $user_data = &lang_user_data();

  my $macros;
  if ($ENV{'DK_MACROS_PATH'}) {
    my $path = $ENV{'DK_MACROS_PATH'};  $macros = do $path or die "do $path failed: $!\n";
  } elsif ($gbl_prefix) {
    my $path = "$gbl_prefix/lib/dakota/macros.pl"; $macros = do $path or die "do $path failed: $!\n";
  } else {
    die;
  }

  $debug = 0;
  if ($ENV{'DKT_MACROS_DEBUG'}) { # 0 or 1 or 2 or 3
    $debug = $ENV{'DKT_MACROS_DEBUG'};
  }
  my $changes = { 'files' => {} };

  my $output_dir = 'macro-system-test-output';
  mkdir $output_dir;
  $Data::Dumper::Indent = 0; # redundant, but added for clarity
  my $num_macros = scalar keys %$macros;
  my $num_tokens = 0;

  foreach my $file (@ARGV) {
    print STDERR $file, "\n";
    my $filestr = &dakota::filestr_from_file($file);
    my $sst = &sst::make($filestr, $file);
    $num_tokens += @{$$sst{'tokens'}};
    &macros_expand($sst, $macros, $user_data);
    #$$changes{'file'}{$file} = &sst::change_report($sst);
    $$changes{'files'}{$file} = $$sst{'changes'};

    my $path = "$output_dir/$file.cc";
    open(my $out, ">", $path) or die "cannot open > $path: $!";
    print $out &sst_fragment::filestr($$sst{'tokens'});
    close($out);
  }
  $Data::Dumper::Indent = 1;
  my $path = "$output_dir/changes.pl";
  open(my $out, ">", $path) or die "cannot open > $path: $!";
  print $out &Dumper($changes);
  close($out);

  my $summary = { 'num-changes' => 0,
                  'num-files'   => scalar keys %{$$changes{'files'}}};
  my $lines = [];
  while (my ($file, $file_info) = each (%{$$changes{'files'}})) {
    while (my ($macro, $macro_info) = each (%{$$file_info{'macros'}})) {
      if (!$$summary{$macro}) {
        $$summary{$macro}{'0'} = 0;
      }
      while (my ($rule, $count) = each (%$macro_info)) {
        $$summary{$macro}{$rule} += $count;
        $$summary{'num-changes'} += $count;
        push @$lines, "$file : $macro : $rule : $count\n";
      }
    }
  }
  $path = "$output_dir/summary.pl";
  open($out, ">", $path) or die "cannot open > $path: $!";
  print $out &Dumper($summary);
  close($out);

  print sort @$lines;
  print "num-files=$$summary{'num-files'}\n";
  print "num-changes-total=$$summary{'num-changes'}\n";
  print "num-macros=$num_macros\n";
  print "num-tokens=$num_tokens\n";
  print "num-macros * num-tokens=" . $num_macros * $num_tokens . "\n";
  print "match-count=$gbl_match_count\n";
};

1;
