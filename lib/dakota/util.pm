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

my $kw_args_generics_tbl;

BEGIN {
  $kw_args_generics_tbl = { 'init' => undef };
};
use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys =  0;
$Data::Dumper::Indent    = 1;  # default = 2

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 add_first
                 add_last
                 canon_path
                 deep_copy
                 dqstr_regex
                 filestr_from_file
                 first
                 flatten
                 header_file_regex
                 ident_regex
                 kw_args_generics
                 kw_args_generics_add
                 last
                 long_suffix
                 max
                 method_sig_regex
                 method_sig_type_regex
                 min
                 objdir
                 remove_first
                 remove_last
                 scalar_from_file
                 split_path
                 sqstr_regex
                 var
              );
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

sub ident_regex {
  my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
  my $mid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!])/x; # method ident
  my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x; # bool   ident
  my $tid = qr/[_a-zA-Z]   [_a-zA-Z0-9-]*?-t/x;                          # type   ident

  my $sco = qr/::/x; # scope resolution operator
  my $rid =  qr/(?:$id$sco?)*$id/;
  my $rmid = qr/(?:$id$sco?)*$mid/;
  my $rbid = qr/(?:$id$sco?)*$bid/;
  my $rtid = qr/(?:$id$sco?)*$tid/;

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
my $build_vars = {
  'objdir' => 'obj',
};
sub objdir { return $$build_vars{'objdir'}; }

sub var {
  my ($compiler, $lhs, $default_rhs) = @_;
  my $result;
  my $compiler_rhs = $$compiler{$lhs};
  my $env_rhs = $ENV{$lhs};

  if ($compiler_rhs) {
    if ($env_rhs) {
      print STDERR "info: $lhs: using environment over config file \"$env_rhs\" over \"$compiler_rhs\"\n";
      $result = $env_rhs;
    } else {
      # using config file
      $result = $compiler_rhs;
    }
  } elsif ($env_rhs) {
    print STDERR "info: $lhs: using environment \"$env_rhs\"\n";
    $result = $env_rhs;
  } else {
    print STDERR "info: $lhs: using default \"$default_rhs\"\n";
    $result = $default_rhs;
  }
  die if !defined $result || $result =~ /^\s+$/; # die if undefined or only whitespace
  die if 'HASH' eq ref($result);

  if ('ARRAY' eq ref($result)) {
    $result = join(' ', @$result);
  }
  return $result;
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
sub canon_path {
  my ($path) = @_;
  if ($path) {
    $path =~ s|//+|/|g; # replace multiple /s with single /s
    $path =~ s|/+\./+|/|g; # replace /./s with single /
    $path =~ s|^\./||g; # remove leading ./
    $path =~ s|/\.$||g; # remove trailing /.
    $path =~ s|/+$||g; # remove trailing /s
  }
  return $path;
}
sub split_path {
  my ($path, $ext_re) = @_;
  my ($vol, $dir, $name) = File::Spec->splitpath($path);
  $dir = &canon_path($dir);
  my $ext;
  if ($ext_re) {
    $ext = $name =~ s|^.+?($ext_re)$|$1|r;
    $name =~ s|^(.+?)$ext_re$|$1|;
  }
  return ($dir, $name, $ext);
}
sub deep_copy {
  my ($ref) = @_;
  return eval &Dumper($ref);
}
sub add_first {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             unshift @$seq, $element; return;
}
sub add_last {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             push    @$seq, $element; return;
}
sub remove_first {
  my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = shift   @$seq;           return $first;
}
sub remove_last {
  my ($seq)           = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = pop     @$seq;           return $last;
}
sub first {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = $$seq[0];  return $first;
}
sub last {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last  = $$seq[-1]; return $last;
}
sub _replace_first {
  my ($seq, $element) = @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_first = &remove_first($seq);
  &add_first($seq, $element);
  return $old_first;
}
sub _replace_last {
  my ($seq, $element) = @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_last = &remove_last($seq);
  &add_last($seq, $element);
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
sub start {
  my ($argv) = @_;
  # just in case ...
}
unless (caller) {
  &start(\@ARGV);
}
1;
