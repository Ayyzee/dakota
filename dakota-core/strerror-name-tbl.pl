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

my $err_set = {};
my $r_err_tbl = {};
my $max_val = 0;

my $prefix = 'E';
my $paths = [split /\s/, `find /usr/include -name "*errno*.h" -print`];
foreach my $path (@$paths) {
  open(my $in, "<", $path) or die "cannot open < $path: $!";

  while (<$in>) {
    if (m/\#\s*define\s+($prefix[A-Z0-9]+)\s+($prefix[A-Z0-9]+|\d+)/) {
      my $err = $1;
      my $val = $2;
      $$err_set{$err} = undef;
      if ($val =~ /^\d+$/) {
        if ($max_val < $val) {
          $max_val = $val;
        }
        if (!exists $$r_err_tbl{$val}) {
          $$r_err_tbl{$val} = {};
        }
        $$r_err_tbl{$val}{$err} = undef;
      }
    }
  }
  close($in);
}
my $i;
my $keys = [sort keys %$err_set];
print "// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-\n\n";
print "static str_t gbl_sys_err_names\[] = {\n";
for (my $i = 0; $i < $max_val + 1; $i++) {
  my $errs = join "|", sort keys %{$$r_err_tbl{$i} ||= {}};
  print "  \"$i\", // $errs\n";
}
print "  nullptr\n";
print "};\n\n";
print "\# define BOGUS -1\n\n";
foreach my $key (@$keys) {
  print "\# if !defined $key\n";
  print "  \# define $key BOGUS\n";
  print "\# endif\n";
}
print "\n";
print "static FUNC set_names() -> void {\n";
foreach my $key (@$keys) {
  print "  if (BOGUS != $key)\n";
  print "    set_name($key, \"$key\");\n";
}
print "  return;\n";
print "}\n";
