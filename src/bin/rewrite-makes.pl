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
&rewrite_sentinal_generic_uses(\$filestr, $kw_args_generics);
print $filestr;

sub rewrite_sentinal_generic_uses_sub {
  my ($name, $arg_list, $kw_args_generics) = @_;
  &rewrite_sentinal_generic_uses(\$arg_list, $kw_args_generics);
  if (1) {
    $arg_list =~ s/$/, nullptr/g;
    $arg_list =~ s/,\s*nullptr\s*,\s*nullptr\s*$/, nullptr/g;
    $arg_list =~ s/^(\s*(object-t|super-t)\s*.*?),\s*nullptr\s*$/$1/g;
  }
  return "$name\($arg_list\)";
}
sub rewrite_sentinal_generic_uses {
  my ($filestr_ref, $kw_args_generics) = @_;
  $$kw_args_generics{'make'} = undef;
  foreach my $name (sort keys %$kw_args_generics) {
    if ('make' ne $name && $name !~ m/^dk::/) {
      $name = "dk::$name";
    }
    $$filestr_ref =~ s/\b($name)\s*\(($main::list_in)\)/&rewrite_sentinal_generic_uses_sub($1, $2, $kw_args_generics)/egms;
  }
  delete $$kw_args_generics{'make'};
}
