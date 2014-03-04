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
		dakota_before_klasses_h
		dakota_before_user_code_h
		dakota_before_rt_code_h
		dakota_method_for_selector_h
		);

my $dakota_h =
'
';
sub dakota_h
{
    return "include <dakota.h>;\n";
    #return $dakota_h;
}

my $dakota_before_klasses_h =
'
';
sub dakota_before_klasses_h
{
    return "include <dakota-before-klasses.h>;\n";
    #return $dakota_before_klasses_h;
}

my $dakota_before_user_code_h =
'
';
sub dakota_before_user_code_h
{
    return "include <dakota-before-user-code.h>;\n";
    #return $dakota_before_user_code_h;
}

my $dakota_before_rt_code_h =
'
';
sub dakota_before_rt_code_h
{
    return "include <dakota-before-rt-code.h>;\n";
    #return $dakota_before_rt_code_h;
}

1;
