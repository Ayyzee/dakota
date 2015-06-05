#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

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

use strict;
use warnings;

package dakota;

my $gbl_compiler;
my $gbl_compiler_default;

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
  my $prefix = &prefix($0);
  unshift @INC, "$prefix/lib";

  $gbl_compiler =         do "$prefix/lib/dakota/compiler.pl"           or die "do $prefix/lib/dakota/compiler.pl failed: $!\n";
  $gbl_compiler_default = do "$prefix/lib/dakota/compiler-linux-gcc.pl" or die "do $prefix/lib/dakota/compiler-linux-gcc.pl failed: $!\n";
};
my $so_ext = &dakota::parse::var($gbl_compiler, 'so_ext', $gbl_compiler_default);

use dakota::parse;
use dakota::util;
use dakota::sst;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $k = qr/[_A-Za-z0-9-]/;
my $z = qr/[_A-Za-z]$k*[A-Za-z0-9_]*/; # dakota identifier
my $ak = qr/::?$k+/;   # absolute scoped dakota identifier
my $rk = qr/$k+$ak*/;  # relative scoped dakota identifier
my $d = qr/\d+/;

if (!defined $ARGV[0])
{ die "usage: macro-system-parser.pl <file> [file ...]\n"; }

my $arg;
foreach $arg (@ARGV)
{
  my $file = $arg;
  my $filestr = &filestr_from_file($file);

  my $sst = &sst::make($filestr, $file);
  my $context = &sst_cursor::make($sst);
  my $result = {};
  my $macros = &_00($context, $result);
  my $str = Dumper $macros;
  print $str;
}
sub _00
{
  my ($sst_cursor, $result) = @_;
  if (&sst_cursor::current_token_p($sst_cursor)) {
    &sst_cursor::match($sst_cursor, "macro");
    my $macro_name = &sst_cursor::match_re($sst_cursor, $z);

    # optionally match 'before' macro sequence: [ ident* ]

    &sst_cursor::match($sst_cursor, "{");
    $$result{$macro_name} =
      { 'rules' => [], 'aux-rules' => {} };
    &_10($sst_cursor, $result, $macro_name);
  }
  return $result;
}
sub _10
{
  my ($sst_cursor, $result, $macro_name) = @_;

  for(&sst_cursor::current_token($sst_cursor)) {
    if (m/$z/) { # aux-rule
      my $name = &sst_cursor::match_re($sst_cursor, $z);
      &_20($sst_cursor, $result, $macro_name, $name);
      last;
    }
    if (m/{/) { # rule
      #&sst_cursor::match($sst_cursor, "{");
      &_30($sst_cursor, $result, $macro_name, undef);
      last;
    }
    if (m/}/) { # macro end
      &sst_cursor::match($sst_cursor, "}");
      &_00($sst_cursor, $result);
      last;
    }
    die;
  }
}
sub _20
{
  my ($sst_cursor, $result, $macro_name, $name) = @_;

  for(&sst_cursor::current_token($sst_cursor)) {
    if (m/{/) { # aux-rule
      #&sst_cursor::match($sst_cursor, "{");
      &_30($sst_cursor, $result, $macro_name, $name);
      last;
    }
    die;
  }
}
sub _30
{
  my ($sst_cursor, $result, $macro_name, $name) = @_;

  my $rule = {};
  #&sst_cursor::match($sst_cursor, "{");
  $$rule{'lhs'} = &body($sst_cursor);
  #&sst_cursor::match($sst_cursor, "}");
  &sst_cursor::match($sst_cursor, "=>");
  #&sst_cursor::match($sst_cursor, "{");
  $$rule{'rhs'} = &body($sst_cursor);
  #&sst_cursor::match($sst_cursor, "}");

  if ($name) { # aux-rule
    $$result{$macro_name}{'aux-rules'}{$name} = $rule;
  } else { # rule
    push @{$$result{$macro_name}{'rules'}}, $rule;
  }
  &_10($sst_cursor, $result, $macro_name);
}
sub body
{
  my ($context) = @_;
  my ($open_token_index, $close_token_index) = &sst_cursor::balenced($context);
  #my $result = &sst_cursor::slice($context, $open_token_index, $close_token_index);
  my $result = [];
  &sst_cursor::match($context, '{');
  my $i = $open_token_index;
  while ($i < $close_token_index - 1) {
    my $token = &sst_cursor::match_any($context);
    &_add_last($result, $token);
    $i++;
  }
  &sst_cursor::match($context, '}');
  return $result;
}
