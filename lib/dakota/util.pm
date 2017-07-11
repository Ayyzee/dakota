#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-
# -*- tab-width: 2
# -*- indent-tabs-mode: nil

# Copyright (C) 2007 - 2017 Robert Nielsen <robert@dakota.org>
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
use sort 'stable';

use Digest::MD5 qw(md5 md5_hex md5_base64);

my $nl = "\n";
my $gbl_prefix;
my $gbl_compiler;
my $h_ext;
my $cc_ext;

sub dk_prefix {
  my ($path) = @_;
  $path =~ s|//+|/|;
  $path =~ s|/\./+|/|;
  $path =~ s|^./||;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    return &dk_prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!\n";
  }
}
use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Data::Dumper;
$Data::Dumper::Terse =     1;
$Data::Dumper::Deepcopy =  1;
$Data::Dumper::Purity =    1;
$Data::Dumper::Useqq =     1;
$Data::Dumper::Sortkeys =  0;
$Data::Dumper::Indent =    1;  # default = 2

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 add_first
                 add_last
                 adjust_path
                 adjust_paths
                 all_files
                 ann
                 as_literal_symbol
                 as_literal_symbol_interior
                 at
                 builddir
                 canon_path
                 clean_paths
                 colin
                 colout
                 cpp_directives
                 ct
                 decode_comments
                 decode_strings
                 deep_copy
                 digsig
                 dir_part
                 dk_mangle
                 dk_mangle_seq
                 dmp
                 do_json
                 dqstr_regex
                 echo_output_path
                 encode_char
                 encode_comments
                 encode_strings
                 filestr_from_file
                 filestr_to_file
                 find_library
                 first
                 flatten
                 global_project
                 target_srcs_ast
                 global_project_target
                 has_kw_args
                 has_kw_arg_names
                 header_file_regex
                 ident_regex
                 int_from_str
                 is_abs
                 is_array_type
                 is_box_type
                 is_debug
                 is_decl
                 is_exe
                 is_exe_target
                 is_exported
                 is_kw_args_method
                 is_out_of_date
                 out_of_date
                 is_same_file
                 is_same_src_file
                 is_slots
                 is_src
                 is_src_decl
                 is_src_defn
                 is_super
                 is_symbol_candidate
                 is_target
                 is_target_decl
                 is_target_defn
                 is_va
                 has_va_prefix
                 kw_arg_generics
                 kw_arg_placeholders
                 kw_args_method_sig
                 last
                 make_dir
                 make_dir_part
                 max
                 method_sig_regex
                 method_sig_type_regex
                 min
                 mtime
                 needs_hex_encoding
                 num_kw_args
                 num_kw_arg_names
                 pann
                 param_types_str
                 project_io_add
                 project_io_append
                 project_io_assign
                 project_io_from_file
                 project_io_remove
                 project_io_to_file
                 relpath
                 remove_extra_whitespace
                 remove_first
                 remove_last
                 remove_name_va_scope
                 remove_non_newlines
                 replace_first
                 replace_last
                 rewrite_klass_defn_with_implicit_metaklass_defn
                 rewrite_scoped_int_uint
                 root_cmd
                 scalar_from_file
                 scalar_to_file
                 set_exe_target
                 set_global_project
                 set_target_srcs_ast
                 set_root_cmd
                 set_src_decl
                 set_src_defn
                 set_target_decl
                 set_target_defn
                 split_path
                 sqstr_regex
                 str_from_seq
                 suffix
                 target_builddir
                 use_abs_path
                 var
                 var_array
 );
use Cwd;
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

my $show_stat_info = 0;
my $global_should_echo = 0;

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &ident_regex();

my $ENCODED_COMMENT_BEGIN = 'ENCODEDCOMMENTBEGIN';
my $ENCODED_COMMENT_END =   'ENCODEDCOMMENTEND';

my $ENCODED_STRING_BEGIN = 'ENCODEDSTRINGBEGIN';
my $ENCODED_STRING_END =   'ENCODEDSTRINGEND';

my $root_cmd;
sub set_root_cmd {
  my ($tbl) = @_;
  $root_cmd = $tbl;
}
sub root_cmd {
  return $root_cmd;
}
sub at {
  my ($tbl, $key) = @_;
  if (exists $$tbl{$key} && defined $$tbl{$key}) {
    return $$tbl{$key};
  }
  return undef;
}
sub ct {
  my ($seq) = @_;
  my $string = join('', @$seq);
  return $string;
}
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
sub remove_non_newlines {
  my ($str) = @_;
  my $result = $str;
  $result =~ s|[^\n]+||gs;
  return $result;
}
sub tear {
  my ($filestr) = @_;
  my $tbl = { 'src' => '', 'src-comments' => '' };
  foreach my $line (split /\n/, $filestr) {
    if ($line =~ m=^(.*?)(/\*.*\*/|//.*)?$=m) {
      $$tbl{'src'} .= $1 . $nl;
      if ($2) {
        $$tbl{'src-comments'} .= $2;
      }
      $$tbl{'src-comments'} .= $nl;
    } else {
      die "$!";
    }
  }
  return $tbl;
}
sub mend {
  my ($filestr_ref, $tbl) = @_;
  my $result = '';
  my $src_lines = [split /\n/, $$filestr_ref];
  my $src_comment_lines = [split /\n/, $$tbl{'src-comments'}];
  #if (scalar(@$src_lines) != scalar(@$src_comment_lines) ) {
  #  print "warning: mend: src-lines = " . scalar(@$src_lines) . ", src-comment-lines = " . scalar(@$src_comment_lines) . $nl;
  #}
  for (my $i = 0; $i < scalar(@$src_lines); $i++) {
    $result .= $$src_lines[$i];
    if (defined $$src_comment_lines[$i]) {
      $result .= $$src_comment_lines[$i];
    }
    $result .= $nl;
  }
  return $result;
}
sub encode_comments {
  my ($filestr_ref) = @_;
  my $tbl = &tear($$filestr_ref);
  $$filestr_ref = $$tbl{'src'};
  return $tbl;
}
sub encode_strings {
  my ($filestr_ref) = @_;
  my $dqstr = &dqstr_regex();
  my $h =  &header_file_regex();
  my $sqstr = &sqstr_regex();
  $$filestr_ref =~ s|($dqstr)|&encode_strings1($1)|eg;
  $$filestr_ref =~ s|(#\s+\w+\s*)(<$h+>)|$1 . &encode_strings1($2)|eg;
  $$filestr_ref =~ s|($sqstr)|&encode_strings1($1)|eg;
}
sub decode_comments {
  my ($filestr_ref, $tbl) = @_;
  $$filestr_ref = &mend($filestr_ref, $tbl);
}
sub decode_strings {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s{$ENCODED_STRING_BEGIN([A-Za-z0-9]*)$ENCODED_STRING_END}{pack('H*',$1)}gseo;
}
# method-ident: allow end in ! or ?
# symbol-ident: allow end in ! or ? and allow . or : or / but never as first nor last char

# -       only interior char (never first nor last)
# .  x2e  only interior char (never first nor last)
# /  x2f  only interior char (never first nor last)
# :  x3a  only interior char (never first nor last)
#
# !  x21  only as last char
# ?  x3f  only as last char

sub remove_extra_whitespace {
  my ($str) = @_;
  $str =~ s/(\w)\s+(\w)/$1__WHITESPACE__$2/g;
  $str =~ s/(:)\s+(::)/$1__WHITESPACE__$2/g;
  $str =~ s/(&)\s+(&&)/$1__WHITESPACE__$2/g;
  $str =~ s/(<)\s+(<<)/$1__WHITESPACE__$2/g;
  $str =~ s/(>)\s+(>>)/$1__WHITESPACE__$2/g;
  $str =~ s/(-)\s+(--)/$1__WHITESPACE__$2/g;
  $str =~ s/(\+)\s+(\+\+)/$1__WHITESPACE__$2/g;
  $str =~ s/(\|)\s+(\|\|)/$1__WHITESPACE__$2/g;
  $str =~ s/\s+//g;
  $str =~ s/__WHITESPACE__/ /g;
  if (0) {
    $str =~ s/\s*->\s*/ -> /g;
    $str =~ s/\s*,\s*/, /g;
  }
  return $str;
}
# oct: 0[0-7]
# hex: 0x
# bin: 0b
sub int_from_str {
  my ($str) = @_;
  my $int = $str;
  my $chars = [split(//, $str)];
  if ('0' eq $$chars[0] && 1 < scalar @$chars) {
    if ($$chars[1] =~ /[0-7]|(x|X)|(b|B)/) {
      $int = oct($str);
    } else {
      die;
    }
  }
  return $int;
}
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
sub rand_str {
  my ($len, $alphabet) = @_;
  if (!$len) {
    $len = 16;
  }
  if (!$alphabet) {
    $alphabet = ["A".."Z", "a".."z", "0".."9"];
  }
  my $str = '';
  $str .= $$alphabet[rand @$alphabet] for 1..$len;
  return $str;
}
sub is_debug {
  return 0;
}
sub is_symbol_candidate {
  my ($str) = @_;
  if ($str =~ m/^$mid$/) {
    return 1;
  } else {
    return 0;
  }
}
sub as_literal_symbol_interior {
  my ($str) = @_;
  $str =~ s/^#\|(.*)\|$/#$1/; # strip only the framing | while leave leading #
  $str =~ s/^#//; # now remove leading #
  return $str;
}
sub as_literal_symbol {
  my ($str) = @_;
  $str =~ s/^#(.+)$/$1/;
  $str =~ s/^\|(.+)\|$/$1/;
  my $result;
  if (&is_symbol_candidate($str)) {
    $result = '#' . $str;
  } else {
    $result = '#|' . $str . '|'
  }
  return $result;
}
my $legal_last_chars = { '?' => 'Q',
                         '!' => 'J' };
my $alphabet = [split(//, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")];
my $alphabet_len = scalar @$alphabet;
sub encode_char {
  my ($char) = @_;
  my $val = $$legal_last_chars{$char};
  if ($val) {
    return $val;
  }
  #return sprintf("%02x", ord($char));
  return $$alphabet[ord($char) % $alphabet_len];
}
sub dk_mangle {
  my ($symbol) = @_;
  # remove \ preceeding |
  $symbol =~ s/\\\|/\|/g;
  my $fix = 0;
  my $fix_str;

  if ($fix) {
    # prevent the (-) from -> to be converted to (_)
    $fix_str = &rand_str();
    $symbol =~ s/->/$fix_str/g;
  }
  # swap underscore (_) with dash (-)
  my $rand_str = &rand_str();
  $symbol =~ s/_/$rand_str/g;
  $symbol =~ s/-/_/g;
  $symbol =~ s/$rand_str/-/g;

  if ($fix) {
    $symbol =~ s/$fix_str/->/g;
  }
  my $ident_symbol = [];

  my $chars = [split //, $symbol];
  my $num_encoded = 0;
  my $last_encoded_char;

  foreach my $char (@$chars) {
    my $part;
    if ($char =~ /\w/) {
      $part = $char;
    } else {
      $part = &encode_char($char);
      $last_encoded_char = $char;
      $num_encoded++;
    }
    &add_last($ident_symbol, $part);
  }
  if ($num_encoded && ! (1 == $num_encoded && $$legal_last_chars{$last_encoded_char})) {
    if (0) {
      &add_first($ident_symbol, '_');
      &add_last( $ident_symbol, '_');
    } else {
      &add_first($ident_symbol, &encode_char('|'));
      &add_last( $ident_symbol, &encode_char('|'));
    }
  }
  &add_first($ident_symbol, '_');
  &add_last( $ident_symbol, '_');
  my $value = &ct($ident_symbol);
  return $value;
}
sub dk_mangle_seq {
  my ($seq) = @_;
  my $ident_symbols = [map { &dk_mangle($_) } @$seq];
  return &ct($ident_symbols);
}
sub ann {
  my ($file, $line, $should_skip) = @_;
  my $string = '';
  return $string if defined $should_skip && 0 != $should_skip;
  if (1) {
    $file =~ s|^.*/(.+)|$1|;
    $string = " // $file:$line:";
  }
  return $string;
}
sub pann {
  my ($file, $line) = @_;
  my $string = '';
  if (0) {
    $string = &ann($file, $line);
  }
  return $string;
}
sub kw_arg_placeholders {
  return { 'default' => '{}', 'nodefault' => '{~}' };
}
# literal symbol/keyword grammar: ^_* ... _*$
# interior only chars: - : . /
# last only chars: ? !
sub ident_regex {
  my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
  my $mid = qr/[_a-zA-Z](?:(?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!]))?/x; # method ident
 #my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x; # bool   ident
  my $bid = qr/[\w-]+\??/x; # bool   ident
  my $tid = qr/[_a-zA-Z]   [_a-zA-Z0-9-]*?-t/x;                          # type   ident

  my $sro =  qr/::/;
  my $rid =  qr/$sro?(?:$id$sro)*$id/;
  my $rmid = qr/$sro?(?:$id$sro)*$mid/;
  my $rbid = qr/$sro?(?:$id$sro)*$bid/;
  my $rtid = qr/$sro?(?:$id$sro)*$tid/;
  my $uint =  qr/0[xX][0-9a-fA-F]+|0[bB][01]+|0[0-7]+|\d+/;
 #my $qtid = qr/(?:$sro?$tid)|(?:$id$sro(?:$id$sro)*$tid)/;

  return ( $id,  $mid,  $bid,  $tid,
          $rid, $rmid, $rbid, $rtid, $uint);
}
my $implicit_metaklass_stmts = qr/( *klass\s+(((klass|trait|superklass)\s+[\w:-]+)|(slots|method|func)).*)/s;
sub rewrite_metaklass_stmts {
  my ($stmts) = @_;
  my $result = $stmts;
  $result =~ s/klass\s+(klass     \s+[\w:-]+)/$1/x;
  $result =~ s/klass\s+(trait     \s+[\w:-]+)/$1/gx;
  $result =~ s/klass\s+(superklass\s+[\w:-]+)/$1/x;
  $result =~ s/klass\s+(slots)               /$1/x;
  $result =~ s/klass\s+(method)              /$1/gx;
  $result =~ s/klass\s+(func)                /$1/gx;
  return $result;
}
sub rewrite_klass_defn_with_implicit_metaklass_defn_replacement {
  my ($s1, $klass_name, $s2, $body) = @_;
  my $result;
  if ($body =~ s/$implicit_metaklass_stmts/"} klass $klass_name-klass { superklass klass;\n" . &rewrite_metaklass_stmts($1)/egs) {
    $result = "klass$s1$klass_name$s2\{ klass $klass_name-klass;" . $body . "}";
  } else {
    $result =  "klass$s1$klass_name$s2\{" . $body . "}";
  }
  return $result;
}
sub rewrite_klass_defn_with_implicit_metaklass_defn {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/^klass(\s+)([\w:-]+)(\s*)\{(\s*$main::block_in\s*)\}/&rewrite_klass_defn_with_implicit_metaklass_defn_replacement($1, $2, $3, $4)/egms;
}
my $int_tbl = {
   'int' =>  'int32',
  'uint' => 'uint32',

   'char' =>  'char8',
  'uchar' => 'uchar8',
  'schar' => 'schar8',

   'bool' => 'boole',
};
sub rewrite_scoped_int_uint_replacement1 {
  my ($name, $rhs) = @_;
  if ($$int_tbl{$name}) {
    $name = $$int_tbl{$name};
  }
  return "$name$rhs";
}
sub rewrite_scoped_int_uint_replacement2 {
  my ($lhs, $name) = @_;
  if ($$int_tbl{$name}) {
    $name = $$int_tbl{$name};
  }
  return "$lhs$name";
}
sub rewrite_scoped_int_uint {
  my ($filestr_ref) = @_;
  # int :: => int64 ::
  # klass int => klass int64
  $$filestr_ref =~ s/($id)(\s*::)/&rewrite_scoped_int_uint_replacement1($1, $2)/ge;
  $$filestr_ref =~ s/(klass\s+)($id)/&rewrite_scoped_int_uint_replacement2($1, $2)/ge;
}
sub header_file_regex {
  return qr|[/.\w-]|;
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
sub dir_part {
  my ($path) = @_;
  my $parts = [split /\//, $path];
  &remove_last($parts);
  my $dir = join '/', @$parts;
  return $dir;
}
sub make_dir {
  my ($path, $should_echo) = @_;
  $path = join('/', @$path) if &is_array($path);
  if (! -e $path) {
    if ($should_echo) {
      print STDERR $0 . ': info: make_dir(' . $path . ')' . $nl;
    }
    my $cmd = ['mkdir', '-p', $path];
    my $exit_val = system(@$cmd);
    if (0 != $exit_val) {
      die $0 . ': error: make_dir(' . $path .')' . $nl;
    }
  }
}
sub make_dir_part {
  my ($path, $should_echo) = @_;
  my $dir_part = &dir_part($path);
  if ('' ne $dir_part) {
    &make_dir($dir_part, $should_echo);
  } elsif (0) {
    print STDERR $0 . ': warning: skipping: make_dir_part(' . $path . ')' . $nl;
  }
}
my $build_vars = {
  'builddir' => 'dkt',
};
sub builddir {
  my $builddir;
  my $project = &global_project();
  if ($project && $$project{'builddir'}) {
    $builddir = $$project{'builddir'};
  } elsif ($ENV{'OBJDIR'}) {
    $builddir = $ENV{'OBJDIR'};
  } else {
    $builddir = $$build_vars{'builddir'};
  }
  die if ! $builddir;
  if (-e $builddir && ! -d $builddir) {
    die;
  }
  if (! -e $builddir) {
    &make_dir($builddir, $global_should_echo);
  }
  return $builddir;
}
sub target_builddir {
  return &builddir . '/x';
}

# 1. cmd line
# 2. environment
# 3. config file
# 4. compile-time default

sub var {
  my ($compiler, $lhs, $default_rhs) = @_;
  my $result = &var_array($compiler, $lhs, $default_rhs);
  if (&is_array($result)) {
    $result = join(' ', @$result);
  }
  return $result;
}

sub var_array {
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
  return $result;
}
sub str_from_seq {
  my ($seq) = @_;
  my $str = &remove_extra_whitespace(join(' ', @$seq)); # str is lexically correct
  return $str;
}
sub param_types_str {
  my ($param_types) = @_;
  my $strs = [];
  foreach my $type (@$param_types) {
    &add_last($strs, &str_from_seq($type));
  }
  my $result = join(',', @$strs);
  return $result;
}
# [ name, fixed-param-types ]
# [ [ x :: signal ], [ object-t, int64-t, ... ] ]
sub kw_args_method_sig {
  my ($method) = @_;
  my $len = 0;
  if (0) {
  } elsif ($len = &num_kw_arg_names($method)) {
  } elsif ($len = &num_kw_args($method)) {
  }
  my $param_types = &deep_copy($$method{'param-types'});
  my $offset = scalar @$param_types - $len;
  my $kw_args = [splice @$param_types, 0, $offset];
  &add_last($kw_args, ['...']);
  return ($$method{'name'}, $kw_args);
}
my $global_project;
sub global_project {
  return $global_project;
}
sub global_project_target {
  my $result = $$global_project{'project.target'};
  $result = $$global_project{'target'} if ! $result;
  return $result;
}
sub set_global_project {
  my ($project_path) = @_;
  $global_project = &scalar_from_file($project_path);
  my $dir = &dir_part(&relpath($project_path));
  if ($dir ne '.') {
    $$global_project{'dir'} = $dir;
  }
  return $global_project;
}
my $target_srcs_ast;
sub target_srcs_ast {
  return $target_srcs_ast;
}
sub set_target_srcs_ast {
  my ($target_srcs_ast_path) = @_;
  $target_srcs_ast = &scalar_from_file($target_srcs_ast_path);
  return $target_srcs_ast;
}
my $gbl_src_file = undef;
my $global_is_target = undef; # <klass>--klasses.{h,cc} vs lib/libdakota--klasses.{h,cc}
my $global_is_defn = undef; # klass decl vs defn
my $global_suffix = undef;
my $global_is_exe_target = undef;

sub set_src_decl {
  my ($path) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  $gbl_src_file = &canon_path("$name.dk");
  $global_is_target =   0;
  $global_is_defn = 0;
  $global_suffix = $h_ext;
}
sub set_src_defn {
  my ($path) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  $gbl_src_file = &canon_path("$name.dk");
  $global_is_target =   0;
  $global_is_defn = 1;
  $global_suffix = $ext;
}
sub set_target_decl {
  my ($path) = @_;
  $gbl_src_file = undef;
  $global_is_target =   1;
  $global_is_defn = 0;
  $global_suffix = $h_ext;
}
sub set_target_defn {
  my ($path) = @_;
  $gbl_src_file = undef;
  $global_is_target =   1;
  $global_is_defn = 1;
  $global_suffix = $cc_ext;
}
sub set_exe_target {
  my ($path) = @_;
  $global_is_exe_target = $path;
}
sub suffix {
  return $global_suffix
}
sub is_src_decl {
  if (!$global_is_target && !$global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_src_defn {
  if (!$global_is_target && $global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_target_decl {
  if ($global_is_target && !$global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_target_defn {
  if ($global_is_target && $global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_src {
  if (!$global_is_target) {
    return 1;
  } else {
    return 0;
  }
}
sub is_target {
  if ($global_is_target) {
    return 1;
  } else {
    return 0;
  }
}
sub is_decl {
  if (!$global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_exe_target {
  return $global_is_exe_target;
}
sub is_exported {
  my ($method) = @_;
  if (exists $$method{'is-exported'} && $$method{'is-exported'}) {
    return 1;
  } else {
    return 0;
  }
}
sub is_slots {
  my ($method) = @_;
  if ('object-t' ne $$method{'param-types'}[0][0]) {
    return 1;
  } else {
    return 0;
  }
}
my $box_type_set = {
  'const slots-t*' => 1,
  'const slots-t&' => 1,
  'slots-t*' => 1,
  'slots-t&' => 1,
  'slots-t'  => 1,
};
sub is_box_type {
  my ($type_seq) = @_;
  my $result;
  my $type_str = &remove_extra_whitespace(join(' ', @$type_seq));

  if ($$box_type_set{$type_str}) {
    $result = 1;
  } else {
    $result = 0;
  }
  return $result;
}
sub is_super {
  my ($generic) = @_;
  if ('super-t' eq $$generic{'param-types'}[0][0]) {
    return 1;
  }
  return 0;
}
sub is_array_type {
  my ($type) = @_;
  my $is_array_type = 0;

  if ($type && $type =~ m|\[.*?\]$|) {
    $is_array_type = 1;
  }
  return $is_array_type;
}
sub is_same_file {
  my ($klass_ast) = @_;
  my $slots_file = &at($$klass_ast{'slots'}, 'file');
  if ($gbl_src_file && $slots_file) {
    return 1 if $gbl_src_file eq &canon_path($slots_file);
  }
  return 0;
}
sub is_same_src_file {
  my ($klass_ast) = @_;
  if ($gbl_src_file && $$klass_ast{'file'}) {
    return 1 if !$ENV{'DK_SRC_UNIQUE_HEADER'};
    return 1 if $gbl_src_file eq &canon_path($$klass_ast{'file'});
  }
  return 0;
}
sub is_array {
  my ($ref) = @_;
  my $state;
  if ('ARRAY' eq ref($ref)) {
    $state = 1;
  } else {
    $state = 0;
  }
  return $state;
}
sub project_io_from_file {
  my ($project_io_path) = @_;
  my $project_io = &scalar_from_file($project_io_path);
  return $project_io;
}
sub project_io_to_file {
  my ($project_io_path, $project_io) = @_;
  &scalar_to_file($project_io_path, $project_io);
}
sub project_io_append {
  my ($line) = @_;
  $$line[-1] = 'undef' if ! $$line[-1];
  #print STDERR join(' ', @$line) . $nl;
}
sub project_io_assign {
  my ($project_io_path, $key, $value) = @_;
  $value = &canon_path($value);
  my $project_io = &project_io_from_file($project_io_path);
  if (! $$project_io{$key} || $value ne $$project_io{$key}) {
    &project_io_append([$key, $value]);
    $$project_io{$key} = $value;
    &project_io_to_file($project_io_path, $project_io);
  }
}
sub project_io_remove {
  my ($project_io, $key, $input) = @_;
  if (&is_array($input)) {
    foreach my $in (@$input) {
      $in = &canon_path($in);
      if ($$project_io{'compile'}{$in}) {
        delete $$project_io{'compile'}{$in};
      }
    }
  } else {
    if ($$project_io{'compile'}{$input}) {
      delete $$project_io{'compile'}{$input};
    }
  }
}
sub project_io_path_remove {
  my ($project_io_path, $key, $input) = @_;
  my $project_io = &project_io_from_file($project_io_path);
  &project_io_remove($project_io, $key, $input);
  &project_io_to_file($project_io_path, $project_io);
}
sub project_io_add {
  my ($project_io_path, $key, $input, $depend) = @_;
  $depend = &canon_path($depend);
  my $project_io = &project_io_from_file($project_io_path);
  $depend = &canon_path($depend);
  if (&is_array($input)) {
    foreach my $in (@$input) {
      $in = &canon_path($in);
      &project_io_append([$key, $in, $depend]);
      $$project_io{$key}{$in} = $depend;
    }
  } else {
    $input = &canon_path($input);
    &project_io_append([$key, $input, $depend]);
    $$project_io{$key}{$input} = $depend;
  }
  &project_io_to_file($project_io_path, $project_io);
}
sub is_va {
  my ($method) = @_;
  if ('va-list-t' eq $$method{'param-types'}[-1][0]) {
    return 1;
  } else {
    return 0;
  }
}
sub has_va_prefix {
  my ($method) = @_;
  if ('va' eq $$method{'name'}[0]) {
    return 1;
  } else {
    return 0;
  }
}
sub num_kw_arg_names {
  my ($func) = @_;
  return scalar @{$$func{'kw-arg-names'} || []};
}
sub has_kw_arg_names {
  my ($func) = @_;
  return $$func{'kw-arg-names'};
}
sub num_kw_args {
  my ($func) = @_;
  return scalar @{$$func{'kw-args'} || []};
}
sub has_kw_args {
  my ($func) = @_;
  return $$func{'kw-args'};
}
sub is_kw_args_method {
  my ($method) = @_;
  return 1 if &num_kw_args($method);
  return 1 if &num_kw_arg_names($method);
  my $state = 0;
  my ($name, $types) = &kw_args_method_sig($method);
  my $name_str =  &str_from_seq($name);
  my $target_srcs_ast = &target_srcs_ast();
  my $tbl = $$target_srcs_ast{'kw-arg-generics'};

  if (exists $$tbl{$name_str}) {
    $state = 1;
  }
  return $state;
}
sub min { my ($x, $y) = @_; return $x <= $y ? $x : $y; }
sub max { my ($x, $y) = @_; return $x >= $y ? $x : $y; }
sub mtime {
  my ($file) = @_;
  if (! -e $file) {
    return 0;
  }
  my $mtime = 9;
  my $result = (stat ($file))[$mtime];
  return $result;
}
sub path_stat {
  my ($path_db, $path, $text) = @_;
  my $stat;
  if (exists $$path_db{$path}) {
    $stat = $$path_db{$path};
  } else {
    if ($show_stat_info) {
      print "STAT $path, text=$text\n";
    }
    @$stat{qw(dev inode mode nlink uid gid rdev size atime mtime ctime blksize blocks)} = stat($path);
  }
  return $stat;
}
sub find_library {
  my ($name, $found_library) = @_;
  my $result;
  if ($found_library) {
    $result = $$found_library{'M2L'}{&canon_path($name)};
  }
  if (! $result) {
    $result = `dakota-find-library $name 2>/dev/null`;
    if (0 == $?) {
      $result =~ s/\s+$//;
    } else {
      $result = $name;
    }
  }
  return $result;
}
sub digsig {
  my ($filestr) = @_;
  my $sig;
  $sig = &md5_hex($filestr);
  $sig =~ s/^.*?([a-fA-F0-9]+)\s*$/$1/s;
  $sig =~ s/^.*?(........)$/$1/s; # extra trim
  return $sig;
}
sub is_out_of_date {
  my ($infiles, $outfile, $file_db) = @_;
  my $files = &out_of_date($infiles, $outfile, $file_db);
  my $result = scalar @$files;
  return $result;
}
sub out_of_date {
  my ($infiles, $outfile, $file_db) = @_;
  my $result = [];
  $file_db = {} if ! defined $file_db;
  if (!&is_array($infiles)) {
    $infiles = [$infiles];
  }
  my $outfile_stat = &path_stat($file_db, $outfile, '--output');
  if (!$$outfile_stat{'mtime'}) {
    return $infiles;
  }
  foreach my $infile (@$infiles) {
    if (! -e $infile) {
      my $tmp_infile = &find_library($infile);
      if ($tmp_infile) {
        $infile = $tmp_infile;
      }
    }
    my $infile_stat =  &path_stat($file_db, $infile,  '--inputs');

    if (!$$infile_stat{'mtime'}) {
      my $cwd = &cwd();
      die $0 . ': warning: no-such-file: ' . $cwd . ' / ' . $infile . ' on which ' . $outfile . ' depends' . $nl;
    }
    if ($$outfile_stat{'mtime'} < $$infile_stat{'mtime'}) {
      &add_last($result, $infile);
    }
  }
  return $result;
}
sub flatten {
    my ($a_of_a) = @_;
    my $a = [map {@$_} @$a_of_a];
    return $a;
}
sub use_abs_path {
  return 0;
}
# found at http://linux.seindal.dk/2005/09/09/longest-common-prefix-in-perl
sub longest_common_prefix {
  if (&use_abs_path()) {
    return '/';
  }
  my $path_prefix = shift;
  for (@_) {
    chop $path_prefix while (! /^$path_prefix/);
  }
  return $path_prefix;
}
sub all_files {
  my ($dirs, $include_regex, $exclude_regex) = @_;
  if (!is_array($dirs)) {
    $dirs = [$dirs];
  }
  my $files = {};
  foreach my $dir (@$dirs) {
    if (-d $dir) {
      &all_files_recursive([$dir], $include_regex, $exclude_regex, $files);
    } else {
      print STDERR $0 . ':warning: skipping non-existent directory ' . $dir . $nl;
    }
  }
  return $files
}
sub all_files_recursive {
  my ($dirs, $include_regex, $exclude_regex, $files) = @_;
  my $raw_dir = join('/', @$dirs);
  my $dir = &Cwd::realpath($raw_dir);
  opendir(my $dh, $dir) || die "can't opendir $dir: $!";
  foreach my $leaf (readdir($dh)) {
    if ('.' ne $leaf && '..' ne $leaf) {
      my $path = $dir . '/' . $leaf;
      if (-d $path) {
        &add_last($dirs, $leaf);
        &all_files_recursive($dirs, $include_regex, $exclude_regex, $files);
        &remove_last($dirs); # remove $leaf
      } elsif (-e $path) {
        if (!defined $include_regex || $path =~ m{$include_regex}) {
          if (!defined $exclude_regex || $path !~ m{$exclude_regex}) {
            my $rel_path_dir = &relpath($dir);
            my $rel_path = $path =~ s=$rel_path_dir=$raw_dir=r;
            $rel_path = &canon_path($rel_path);
            $$files{$path} = $rel_path;
          }
        }
      }
    }
  }
  closedir $dh;
  return $files;
}
sub dmp {
  my ($ref) = @_;
  print STDERR &Dumper($ref);
}
sub adjust_path {
  my ($dir, $input, $force) = @_;
  $force = 0 if ! $force;
  my $rel_input = $input;
  if (&is_abs($input)) {
    $rel_input = &relpath($input);
    #die if ! -e $rel_input;
    return $rel_input;
  }
  if ($force || (! -e $input && -e "$dir/$input")) {
    $rel_input = &relpath("$dir/$input");
  }
  #die if ! -e $rel_input;
  return $rel_input;
}
sub adjust_paths {
  my ($dir, $inputs, $force) = @_;
  my $rel_inputs = [];
  foreach my $input (@$inputs) {
    my $rel_input = &adjust_path($dir, $input, $force);
    &add_last($rel_inputs, $rel_input);
  }
  return $rel_inputs;
}
sub clean_paths {
  my ($in, $key) = @_;
  die if !defined $in;
  if ($key && !exists $$in{$key}) {
    die &Dumper($in);
  }
  my $items_in = $in;
  if ($key) {
    $items_in = $$in{$key};
  }
  my $items = [map { &canon_path($_) } @$items_in];
  $items = &copy_no_dups($items);
  if ($key) {
    $$in{$key} = $items;
  }
  return $items;
}
my $gbl_col_width = '  ';
sub colin {
  my ($col) = @_;
  my $len = length($col)/length($gbl_col_width);
  #print STDERR "$len" . "++" . $nl;
  $len++;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub colout {
  my ($col) = @_;
  &confess("Aborted because of &colout(0)") if '' eq $col;
  my $len = length($col)/length($gbl_col_width);
  #print STDERR "$len" . "--" . $nl;
  $len--;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub copy_no_dups {
  my ($strs) = @_;
  my $cmd_info = &root_cmd();
  my $str_set = {};
  my $result = [];
  foreach my $str (@$strs) {
    if (! $$cmd_info{'opts'}{'precompile'} && ! -e $str) {
      if ($str eq &find_library($str)) {
        my $cwd = &cwd();
        print STDERR $0 . ': warning: no-such-file: ' . $cwd . ' / ' . $str . $nl;
      }
    }
    if (&is_abs($str)) {
      $str = &canon_path($str);
    } else {
      $str = &relpath($str);
    }
    if (!$$str_set{$str}) {
      &add_last($result, $str);
      $$str_set{$str} = 1;
    } else {
      #printf "$0: warning: removing duplicate $str\n";
    }
  }
  return $result;
}
sub is_exe {
  my ($cmd_info, $project) = @_;
  my $is_exe = 1;
  if ($$cmd_info{'opts'}{'dynamic'} || $$cmd_info{'opts'}{'shared'}) {
    $is_exe = 0;
  }
  if (!$project && $$cmd_info{'opts'}{'project'}) {
    $project = &scalar_from_file($$cmd_info{'opts'}{'project'});
  }
  if (! $is_exe && ! $$project{'is-lib'}) {
    print STDERR $0 . ": warning: missing '\"is-lib\" : 1' in " . $$cmd_info{'opts'}{'project'} . $nl;
  }
  return !$$project{'is-lib'};
}
sub is_abs {
  my ($path) = @_;
  die if !$path;
  my $result = File::Spec->file_name_is_absolute($path);
  return $result;
}
sub realpath {
  my ($path) = @_; # base is optional
  my $result = Cwd::realpath($path);
  return $result;
}
sub relpath {
  my ($path, $base) = @_; # base is optional
  die if !$path;
  return $path if ! &is_abs($path);
  $path = &realpath($path);
  if ($base) {
    $base = &realpath($base);
  }
  die if !$path;
  my $result = File::Spec->abs2rel($path, $base); # base is optional
  return $result;
}
sub canonpath {
  my ($path) = @_;
  die if !$path;
  my $result = File::Spec->canonpath($path);
  return $result;
}
sub canon_path {
  my ($path) = @_;
  if ($path) {
    $path =~ s|//+|/|g; # replace multiple /s with single /s
    $path =~ s|/+\./+|/|g; # replace /./s with single /
    $path =~ s|^\./(.+)|$1|g; # remove leading ./
    $path =~ s|(.+)/\.$|$1|g; # remove trailing /.
    $path =~ s|/+$||g; # remove trailing /s
    $path =~ s|/[^/]+/\.\./|/|g; # /xx/../ => /
  }
  return $path;
}
sub split_path {
  my ($path, $ext_re) = @_;
  die if !$path;
  my ($vol, $dir, $name) = File::Spec->splitpath($path);
  $dir = &canon_path($dir);
  my $ext;
  if ($ext_re) {
    $ext = $name =~ s|^.+?($ext_re)$|$1|r;
    $name =~ s|^(.+?)\.$ext_re$|$1|;
  }
  return ($dir, $name, $ext);
}
sub deep_copy {
  my ($ref) = @_;
  return eval &Dumper($ref);
}
sub do_json {
  my ($path) = @_;
  local undef $/;
  open(my $fh, "<", $path);
  my $str = <$fh>;
  close($fh);
  return eval($str);
}
sub remove_name_va_scope {
  my ($method) = @_;
  #die if 'va' ne $$method{'name'}[0];
  #die if 'va-list-t' ne $$method{'param-types'}[-1];
  if (3 == scalar @{$$method{'name'}} && 'va' eq $$method{'name'}[0] && '::' eq $$method{'name'}[1]) {
    &remove_first($$method{'name'});
    &remove_first($$method{'name'});
  }
  else { print "not-va-method: " . &Dumper($method); }
}
sub add_first {
  my $seq = shift @_;
  if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             unshift @$seq, @_; return;
}
sub add_last {
  my $seq = shift @_;
  if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             push    @$seq, @_; return;
}
sub remove_first {
  my ($seq) =           @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = shift   @$seq;           return $first;
}
sub remove_last {
  my ($seq) =           @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last =  pop     @$seq;           return $last;
}
sub first {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $first = $$seq[0];  return $first;
}
sub last {
  my ($seq) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; } my $last =  $$seq[-1]; return $last;
}
sub replace_first {
  my $seq = shift @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_first = &remove_first($seq);
  &add_first($seq, @_);
  return $old_first;
}
sub replace_last {
  my $seq = shift @_;
  if (!defined $seq) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  my $old_last = &remove_last($seq);
  &add_last($seq, @_);
  return $old_last;
}
sub unwrap_seq {
  my ($seq) = @_;
  $seq =~ s/\s*\n+\s*/ /gms;
  $seq =~ s/\s+/ /gs;
  return $seq;
}
sub write_filestr_to_file {
  my ($filestr, $file) = @_;
  &make_dir_part($file);
  open FILE, ">", $file or die __FILE__, ":", __LINE__, ": ERROR: " . &cwd() . " / " . $file . ": $!" . $nl;
  flock FILE, LOCK_EX or die;
  truncate FILE, 0;
  print FILE $filestr;
  flock FILE, LOCK_UN or die;
  close FILE            or die __FILE__, ":", __LINE__, ": ERROR: " . &cwd() . " / " . $file . ": $!" . $nl;
}
sub echo_output_path {
  my ($file, $filestr_sig, $filestr) = @_;
  if (1) {
    if (1) {
      print $file . $nl;
    } else {
      if (!$filestr_sig) {
        if (!$filestr) {
          $filestr = &filestr_from_file($file);
        }
        $filestr_sig = &digsig($filestr);
      }
      print $file . '  ' . $filestr_sig . $nl;
    }
  }
}
sub filestr_to_file {
  my ($filestr, $file, $should_echo) = @_;
  &write_filestr_to_file($filestr, $file);
  if (0) {
    my $filestr_sig = &digsig($filestr);
    my $file_md5 = "$file.md5";
    &write_filestr_to_file($filestr_sig . $nl, $file_md5);
    &echo_output_path($file, $filestr_sig, $filestr) if $should_echo;
  }
}
sub scalar_to_file {
  my ($file, $ref) = @_;
  if (!defined $ref) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_to_file(\"$file\", $ref)\n";
  }
  my $refstr = '# -*- mode: perl -*-' . $nl . &Dumper($ref);
  &filestr_to_file($refstr, $file);
}
sub scalar_from_file {
  my ($file) = @_;
  die if ! -e $file;
  my $initial_count = 10; # total hack to hide race condition
  my $count = $initial_count;
  my $fail_count = $count;
  my $result;
  while ($count--) {
    my $filestr = &filestr_from_file($file);
    $result = eval $filestr;

    if (!defined $result) {
      print STDERR __FILE__, ":", __LINE__, ": WARNING: scalar_from_file(\"$file\")\n";
      #print STDERR "<" . $filestr . ">" . $nl;
      $fail_count--;
      next;
    }
    last;
  }
  if ($fail_count == 0) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_from_file(\"$file\")\n";
  }
  return $result;
}
sub filestr_from_file {
  my ($file) = @_;
  if (! -e $file) {
    die __FILE__, ":", __LINE__, ": ERROR: " . &cwd() . " / " . $file . ": $!" . $nl;
  }
  undef $/; ## force files to be read in one slurp
  open FILE, "<", $file or die __FILE__, ":", __LINE__, ": ERROR: " . &cwd() . " / " . $file . ": $!" . $nl;
  flock FILE, LOCK_SH or die;
  my $filestr = <FILE>;
  flock FILE, LOCK_UN or die;
  close FILE            or die __FILE__, ":", __LINE__, ": ERROR: " . &cwd() . " / " . $file . ": $!" . $nl;
  return $filestr;
}
sub start {
  my ($argv) = @_;
  # just in case ...
}
BEGIN {
  $gbl_prefix = &dk_prefix($0);
  $gbl_compiler = &do_json("$gbl_prefix/lib/dakota/compiler/command-line.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/compiler/command-line.json\") failed: $!\n";
  $h_ext = &var($gbl_compiler, 'h_ext', undef);
  $cc_ext = &var($gbl_compiler, 'cc_ext', undef);
};
unless (caller) {
  &start(\@ARGV);
}
1;
