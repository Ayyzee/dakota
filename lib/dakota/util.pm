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

package dakota::util;

use strict;
use warnings;
use Data::Dumper;

my $kw_args_generics_tbl;

BEGIN {
  $kw_args_generics_tbl = { 'init' => undef };
};

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
                 kw_args_generics
                 kw_args_generics_add
                 filestr_from_file
                 scalar_from_file
                 canon_path
                 flatten
                 min
                 max
                 long_suffix
                 ident_regex
                 header_file_regex
                 dqstr_regex
                 sqstr_regex
                 method_sig_type_regex
                 method_sig_regex
              );

use Fcntl qw(:DEFAULT :flock);
sub ident_regex {
  my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
  my $mid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!])/x; # method ident
  my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x; # bool   ident
  my $tid = qr/[_a-zA-Z]   [_a-zA-Z0-9-]*?-t/x;                          # type   ident

  my $rid =  qr/(?:$id\::?)*$id/;
  my $rmid = qr/(?:$id\::?)*$mid/;
  my $rbid = qr/(?:$id\::?)*$bid/;
  my $rtid = qr/(?:$id\::?)*$tid/;

  return ( $id,  $mid,  $bid,  $tid,
          $rid, $rmid, $rbid, $rtid);
}
my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &ident_regex();
sub header_file_regex {
  return qr|[/._A-Za-z0-9-]|;
}
sub method_sig_type_regex {
  return qr/object-t|slots-t|slots-t\s*\*/;
}
my $method_sig_type = &method_sig_type_regex();
sub method_sig_regex {
  return qr/(va:)?$mid(\($method_sig_type?\))?/;
}
sub long_suffix {
  return { '?' => 'p',
           '!' => 'd' };
}
sub dqstr_regex {
  # not-escaped " .*? not-escaped "
  return qr/(?<!\\)".*?(?<!\\)"/;
}
sub sqstr_regex {
# not-escaped ' .*? not-escaped '
  return qr/(?<!\\)'.*?(?<!\\)'/;
}
sub kw_args_generics_add {
  my ($generic) = @_;
  my $tbl = &kw_args_generics();
  $$tbl{$generic} = undef;
}
sub kw_args_generics {
  return $kw_args_generics_tbl;
}
sub min { my ($x, $y) = @_; return $x <= $y ? $x : $y; }
sub max { my ($x, $y) = @_; return $x >= $y ? $x : $y; }
sub flatten {
    my ($a_of_a) = @_;
    my $a = [map {@$_} @$a_of_a];
    return $a;
}
sub canon_path { # should merge with rel_path_canon()
  my ($path) = @_;
  $path =~ s|//+|/|g; # replace multiple /s with single /s
  $path =~ s|/+\./+|/|g; # replace /./s with single /
  $path =~ s|^\./||g; # remove leading ./
  $path =~ s|/\.$||g; # remove trailing /.
  $path =~ s|/+$||g; # remove trailing /s
  return $path;
}
sub deep_copy {
  my ($ref) = @_;
  return eval &Dumper($ref);
}
sub _add_first {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             unshift @$seq, $element; return;
}
sub _add_last {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             push    @$seq, $element; return;
}
sub _remove_first {
  my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = shift   @$seq;           return $first;
}
sub _remove_last {
  my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = pop     @$seq;           return $last;
}
sub _first {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = $$seq[0];  return $first;
}
sub _last {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = $$seq[-1]; return $last;
}
sub _replace_first {
  my ($seq, $element) = @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_first = &_remove_first($seq);
  &_add_first($seq, $element);
  return $old_first;
}
sub _replace_last {
  my ($seq, $element) = @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_last = &_remove_last($seq);
  &_add_last($seq, $element);
  return $old_last;
}
sub scalar_from_file {
  my ($file) = @_;
  my $filestr = &filestr_from_file($file);
  $filestr = eval $filestr;

  if (!defined $filestr) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_from_file(\"$file\")\n";
  }
  return $filestr;
}
sub filestr_from_file {
  my ($file) = @_;
  undef $/; ## force files to be read in one slurp
  open FILE, "<$file" or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
  flock FILE, LOCK_SH;
  my $filestr = <FILE>;
  close FILE;
  return $filestr;
}

1;
