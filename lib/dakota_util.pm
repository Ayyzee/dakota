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
		_first
		_last
		_add_first
		_add_last
		_remove_first
		_remove_last 
		deep_copy
		kw_arg_generics
		kw_arg_generics_add
		filestr_from_file
		scalar_from_file
		);

use Fcntl qw(:DEFAULT :flock);

my $kw_arg_generics_tbl = { 'init' => undef };

sub kw_arg_generics_add
{
    my ($generic) = @_;
    $$kw_arg_generics_tbl{$generic} = undef;
}

sub kw_arg_generics
{
    return $kw_arg_generics_tbl;
}

sub deep_copy
{
    my ($ref) = @_;
    return eval &Dumper($ref);
}

sub _add_first   { my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             unshift @$seq, $element; return;        }
sub _add_last    { my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             push    @$seq, $element; return;        }
sub _remove_first{ my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = shift   @$seq;           return $first; }
sub _remove_last { my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = pop     @$seq;           return $last;  }

sub _first{ my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = $$seq[0];  return $first; }
sub _last { my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = $$seq[-1]; return $last;  }

sub _replace_first
{
    my ($seq, $element) = @_;
    if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }
    my $old_first = &_remove_first($seq);
    &_add_first($seq, $element);
    return $old_first;
}

sub _replace_last
{
    my ($seq, $element) = @_;
    if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }
    my $old_last = &_remove_last($seq);
    &_add_last($seq, $element);
    return $old_last;
}

sub scalar_from_file
{
    my ($file) = @_;
    my $filestr = &filestr_from_file($file);
    $filestr = eval $filestr;

    if (!defined $filestr)
    {
        print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_from_file(\"$file\")\n";
    }
    return $filestr;
}

sub filestr_from_file
{
    my ($file) = @_;

    undef $/;  ## force files to be read in one slurp
    open FILE, "<$file" or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
    flock FILE, LOCK_SH;
    my $filestr = <FILE>;
    close FILE;
    
    return $filestr;
}

1;
