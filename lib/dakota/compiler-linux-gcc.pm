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

package dakota::compiler;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
  var
  );

my $vars = {
  'O_EXT' =>  'o',
  'SO_EXT' => 'so',

  'CXX' =>            'g++',
  'CXXFLAGS' =>       '-std=c++11',

  'LD_SONAME_FLAGS' => '-soname',

  'CXX_NO_WARNINGS_FLAGS' => '--no-warnings',
  'CXX_COMPILE_FLAGS' =>     '--compile --PIC',
  'CXX_SHARED_FLAGS' =>      '--shared',
  'CXX_DYNAMIC_FLAGS' =>     '--dynamic',
  'CXX_OUTPUT_FLAGS' =>      '--output',
  'CXX_OPTIMIZE_FLAGS' =>    '--optimize=0',

  'CXX_DEBUG_FLAGS' =>       "\
 --debug=3\
 --define-macro DEBUG\
",

  'CXX_WARNINGS_FLAGS' =>    "\
 --no-common\
 --trapv\
 --all-warnings\
 --warn-cast-qual\
 --warn-extra\
 --warn-format=2\
 --warn-missing-format-attribute\
 --warn-missing-include-dirs\
 --warn-no-variadic-macros\
 --warn-pointer-arith\
 --warn-shadow\
 --warn-switch-enum\
 --warn-undef\
 --warn-unused\
 --warn-no-multichar\
 --warn-conversion\
 --warn-redundant-decls\
 --warn-switch-default\
"
};

sub var {
  my ($lhs, $default_rhs) = @_;
  my $result;
  if (defined $ENV{$lhs}) {
    $result = $ENV{$lhs};
  } else {
    $result = $$vars{$lhs};
  }
  $result = $default_rhs if !defined $result;
  $result =~ s/\n/ /g;
  $result =~ s/\s+/ /g;
  return $result;
}

1;
