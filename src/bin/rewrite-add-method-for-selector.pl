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

use strict;
use warnings;

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

my $kw_args_generics = { 'init' => undef,
                       };

undef $/;
my $filestr = <STDIN>;
&rewrite_add_method_for_selector(\$filestr);
print $filestr;

sub remove_extra_whitespace {
  my ($str) = @_;
  $str =~ s|(\w)\s+(\w)|$1__WHITESPACE__$2|g;
  $str =~ s|\s+||g;
  $str =~ s|__WHITESPACE__| |g;
  return $str;
}
sub rewrite_add_method_for_selector_sub {
  my ($ws1, $ws2, $arglist) = @_;
  my $members_info = &arglist_members($arglist);
  #my $offset = $$members_info[0];
  my ($kls, $selector1, $selector2, $function) = @{$$members_info[1]};
  my $result = '';
  #$ws2 =~ s/  $//; # remove 2 spaces
  $result .= sprintf("%sdk::add-method-for-selector%s(%s,\n", $ws1, $ws2, $kls);
  $result .= sprintf("%s                           %s %s,\n", $ws1, $ws2, $selector1);
  $result .= sprintf("%s                           %s dk::method-for-selector(%s, %s));\n", $ws1, $ws2, $kls, &remove_extra_whitespace($selector2));
  #
  $result .= sprintf("%sdk::add-method-for-selector%s(%s,\n", $ws1, $ws2, $kls);
  $result .= sprintf("%s                           %s %s,\n", $ws1, $ws2, $selector2);
  $result .= sprintf("%s                           %s cast(method-t)%s);\n", $ws1, $ws2, $function);
  return $result;
}
sub rewrite_add_method_for_selector {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/( *)SHIFT-AND-ADD-FUNCTION-FOR-SELECTOR( *)\(($main::list_in)\)\s*;/&rewrite_add_method_for_selector_sub($1, $2, $3)/egms;
}

my $open =  { '(' => 1, '{' => 1, '[' => 1 };
my $close = { ')' => 1, '}' => 1, ']' => 1 };

sub arglist_members {
  my ($arglist, $i) = @_;
  my $result = [];
  my $tkn = '';
  my $is_framed = 0;
  my $chars = [split(//, $arglist)];
  if (!$i) { $i = 0; }
  #print STDERR scalar @$chars . "\n";

  while (scalar @$chars > $i) {
    if (!$is_framed) {
      if (',' eq $$chars[$i]) {
        push @$result, $tkn; $tkn = '';
        $i++; # eat comma
        while ($$chars[$i] =~ m/(\s|\n)/) { $i++; } # eat whitespace
      } elsif (')' eq $$chars[$i]) {
        print STDERR "warning: &arglist_members() argument unbalenced: close token at offset $i\n";
        last;
      }
    }
    if ('(' eq $$chars[$i]) {
      $is_framed++;
    } elsif (')' eq $$chars[$i] && $is_framed) {
      $is_framed--;
    }
    $tkn .= $$chars[$i];
    $i++;
  }
  if ($tkn) {
    push @$result, $tkn;
  }
  return [ $i , $result ];
}
