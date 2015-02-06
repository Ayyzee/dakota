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
