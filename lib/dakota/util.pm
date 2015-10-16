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
#use Carp;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

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
                 ann
                 canon_path
                 cpp_directives
                 decode_comments
                 decode_cpp
                 decode_strings
                 deep_copy
                 dqstr_regex
                 encode_char
                 encode_comments
                 encode_cpp
                 encode_strings
                 filestr_from_file
                 first
                 flatten
                 header_file_regex
                 ident_regex
                 kw_args_generics
                 kw_args_generics_add
                 kw_args_placeholders
                 last
                 make_ident_symbol
                 make_ident_symbol_scalar
                 max
                 method_sig_regex
                 method_sig_type_regex
                 min
                 needs_hex_encoding
                 objdir
                 pann
                 remove_first
                 remove_last
                 scalar_from_file
                 split_path
                 sqstr_regex
                 var
              );
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();

my $ENCODED_COMMENT_BEGIN = '__ENCODED_COMMENT_BEGIN__';
my $ENCODED_COMMENT_END =   '__ENCODED_COMMENT_END__';

my $ENCODED_STRING_BEGIN = '__ENCODED_STRING_BEGIN__';
my $ENCODED_STRING_END =   '__ENCODED_STRING_END__';

sub concat3 {
  my ($s1, $s2, $s3) = @_;
  return "$s1$s2$s3";
}
sub concat5 {
  my ($s1, $s2, $s3, $s4, $s5) = @_;
  return "$s1$s2$s3$s4$s5";
}
sub encode_strings5 {
  my ($s1, $s2, $s3, $s4, $s5) = @_;
  return &concat5($s1, $s2, unpack('H*', $s3), $s4, $s5);
}
sub encode_comments3 {
  my ($s1, $s2, $s3) = @_;
  return &concat5($s1, $ENCODED_COMMENT_BEGIN, unpack('H*', $s2), $ENCODED_COMMENT_END, $s3);
}
sub encode_strings1 {
  my ($s) = @_;
  $s =~ m/^(.)(.*?)(.)$/;
  my ($s1, $s2, $s3) = ($1, $2, $3);
  return &encode_strings5($s1, $ENCODED_STRING_BEGIN, $s2, $ENCODED_STRING_END, $s3);
}
sub encode_comments {
  my ($filestr_ref) = @_;
    $$filestr_ref =~ s|(//)(.*?)(\n)|&encode_comments3($1, $2, $3)|egs;
    $$filestr_ref =~ s|(/\*)(.*?)(\*/)|&encode_comments3($1, $2, $3)|egs;
}
sub encode_strings {
  my ($filestr_ref) = @_;
  my $dqstr = &dqstr_regex();
  my $h  = &header_file_regex();
  my $sqstr = &sqstr_regex();
  $$filestr_ref =~ s|($dqstr)|&encode_strings1($1)|eg;
  $$filestr_ref =~ s|(<$h+>)|&encode_strings1($1)|eg;
  $$filestr_ref =~ s|($sqstr)|&encode_strings1($1)|eg;
}
sub decode_comments {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s{$ENCODED_COMMENT_BEGIN([A-Za-z0-9]*)$ENCODED_COMMENT_END}{pack('H*',$1)}gseo;
}
sub decode_strings {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s{$ENCODED_STRING_BEGIN([A-Za-z0-9]*)$ENCODED_STRING_END}{pack('H*',$1)}gseo;
}
my $directives = {
  'define' => '\w+',
  'elif' => '(\w+|\d+|!|\()',
  'else' => undef,
  'endif' => undef,
  'error' => '".*?"',
  'if' => '(\w+|\d+|!|\()',
  'ifdef' => '\w+',
  'ifndef' => '\w+',
  'include' => '(".+?"|<.+?>)',,
  'line' => '\d+',
  'pragma' => undef,
  'undef' => '\w+',
  'warning' => '".*?"',
};
sub encode_cpp {
  my ($filestr_ref) = @_;
  foreach my $directive (keys %$directives) {
    my $next_tkn_regex = $$directives{$directive};
    if ($next_tkn_regex) {
      $$filestr_ref =~ s/^(\s*)#(\s*$directive\s+$next_tkn_regex.*)$/$1\@\@\@$2/gm;
    } else {
      $$filestr_ref =~ s/^(\s*)#(\s*$directive\b.*)$/$1\@\@\@$2/gm;
    }
  }
}
sub decode_cpp {
  my ($filestr_ref) = @_;
  foreach my $directive (keys %$directives) {
    my $next_tkn_regex = $$directives{$directive};
    if ($next_tkn_regex) {
      $$filestr_ref =~ s/^(\s*)\@\@\@(\s*$directive\s+$next_tkn_regex.*)$/$1#$2/gm;
    } else {
      $$filestr_ref =~ s/^(\s*)\@\@\@(\s*$directive\b.*)$/$1#$2/gm;
    }
  }
}
# method-ident: allow end in ! or ?
# symbol-ident: allow end in ! or ? and allow . or : never as first char

# !  x21  \u0021  only as last char
# .  x2e  \u002e  never as first char
# :  x3a  \u003a  never as first char
# ?  x3f  \u003f  only as last char

sub needs_hex_encoding {
  my ($str) = @_;
  $str =~ s/^#//;
  my $k = qr/[\w-]/;
  foreach my $char (split(//, $str)) {
    if ($char !~ m/$k/) {
      return 1;
    }
  }
  return 0;
}
sub encode_char { my ($char) = @_; return sprintf("%02x", ord($char)); }
sub make_ident_symbol_scalar {
  my ($symbol) = @_;
  my $k = qr/[\w-]/;
  my $ident_symbol = [];
  &dakota::util::add_first($ident_symbol, '_');

  my $chars = [split //, $symbol];

  foreach my $char (@$chars) {
    my $part;
    if ($char eq '-') {
      $part = '_';
    } elsif ($char =~ /$k/) {
      $part = $char;
    } else {
      $part = &encode_char($char);
    }
    &dakota::util::add_last($ident_symbol, $part);
  }
  &dakota::util::add_last($ident_symbol, '_');
  my $value = &path::string($ident_symbol);
  return $value;
}
sub make_ident_symbol {
  my ($seq) = @_;
  my $ident_symbols = [map { &make_ident_symbol_scalar($_) } @$seq];
  return &path::string($ident_symbols);
}
sub ann {
  my ($file, $line, $msg) = @_;
  my $string = '';
  if (1) {
    $file =~ s|^.*/(.+)|$1|;
    $string = " /* $file:$line:";
    if ($msg) {
      $string .= " $msg";
    }
    $string .= " */";
  }
  return $string;
}
sub pann {
  my ($file, $line, $msg) = @_;
  my $string = '';
  if (0) {
    $string = &ann($file, $line, $msg);
  }
  return $string;
}
sub kw_args_placeholders {
  return { 'default' => '{}', 'nodefault' => '{~}' };
}
sub ident_regex {
  my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
  my $mid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!])/x; # method ident
  my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x; # bool   ident
  my $tid = qr/[_a-zA-Z]   [_a-zA-Z0-9-]*?-t/x;                          # type   ident

  my $sro =  qr/::/;
  my $rid =  qr/(?:$id$sro)*$id/;
  my $rmid = qr/(?:$id$sro)*$mid/;
  my $rbid = qr/(?:$id$sro)*$bid/;
  my $rtid = qr/(?:$id$sro)*$tid/;
 #my $qtid = qr/(?:$sro?$tid)|(?:$id$sro(?:$id$sro)*$tid)/;

  return ( $id,  $mid,  $bid,  $tid,
          $rid, $rmid, $rbid, $rtid);
}
sub header_file_regex {
  return qr|[/._A-Za-z0-9-]|;
}
sub method_sig_type_regex {
  return qr/object-t|slots-t|slots-t\s*\*/;
}
my $method_sig_type = &method_sig_type_regex();
sub method_sig_regex {
  return qr/(va::)?$mid(\($method_sig_type?\))?/;
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

# 1. cmd line
# 2. environment
# 3. config file
# 4. compile-time default

sub var {
  my ($compiler, $lhs, $default_rhs) = @_;
  my $result;
  my $env_rhs = $ENV{$lhs};
  my $compiler_rhs = $$compiler{$lhs};

  if ($env_rhs) {
    $result = $env_rhs;
  } elsif ($compiler_rhs) {
    $result = $compiler_rhs;
  } else {
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
