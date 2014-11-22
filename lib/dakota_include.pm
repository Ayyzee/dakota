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

use strict;
use warnings;

package dakota;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
		dakota_h
		dakota_before_h
		dakota_before_user_code_h
		dakota_after_user_code_h
		dakota_method_for_selector_h
		user_code_cxx
		);
my $cxx_ext = 'cc';

sub dakota_h { return "include <dakota.h>;\n"; }

sub dakota_before_h { return "include <dakota-before.h>;\n"; }

sub dakota_before_user_code_h { return "include <dakota-before-user-code.h>;\n"; }

sub dakota_after_user_code_h { return "include <dakota-after-user-code.h>;\n"; }

sub user_code_cxx
{
    my ($name) = @_;
    if (exists $ENV{'DK_ABS_PATH'}) {
	my $cwd = getcwd;
	return "include \"$cwd/obj/$name.$cxx_ext\";\n";
    }
    else {
	# should not be hardcoded
	return "include \"../$name.$cxx_ext\";\n";
    }
}

1;
