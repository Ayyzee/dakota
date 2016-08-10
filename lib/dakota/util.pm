#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-
# -*- tab-width: 2
# -*- indent-tabs-mode: nil

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
use sort 'stable';

use Digest::MD5 qw(md5 md5_hex md5_base64);

my $nl = "\n";
my $gbl_prefix;

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
BEGIN {
  $gbl_prefix = &dk_prefix($0);
};
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
                 all_files
                 ann
                 as_literal_symbol
                 as_literal_symbol_interior
                 canon_path
                 clean_paths
                 cpp_directives
                 ct
                 decode_comments
                 decode_strings
                 deep_copy
                 dir_part
                 dmp
                 dqstr_regex
                 encode_char
                 encode_comments
                 encode_strings
                 filestr_from_file
                 filestr_to_file
                 find_library
                 first
                 flatten
                 header_file_regex
                 ident_regex
                 is_abs
                 is_exe
                 is_symbol_candidate
                 is_debug
                 is_kw_args_generic
                 is_out_of_date
                 is_va
                 kw_args_generics
                 kw_args_generics_sig
                 kw_args_placeholders
                 last
                 at
                 dk_mangle_seq
                 dk_mangle
                 make_dir
                 make_dir_part
                 max
                 method_sig_regex
                 method_sig_type_regex
                 min
                 mtime
                 needs_hex_encoding
                 builddir
                 pann
                 parameter_types_str
                 project_io_add
                 project_io_remove
                 project_io_append
                 project_io_assign
                 project_io_from_file
                 project_io_to_file
                 rel_path_canon
                 relpath
                 remove_extra_whitespace
                 remove_first
                 remove_last
                 remove_non_newlines
                 remove_name_va_scope
                 rewrite_klass_defn_with_implicit_metaklass_defn
                 scalar_from_file
                 scalar_to_file
                 split_path
                 sqstr_regex
                 str_from_seq
                 var
                 var_array
                 global_project
                 set_global_project
                 global_project_ast
                 set_global_project_ast
                 global_project_target
                 use_abs_path
                 set_root_cmd
                 root_cmd
              );
use Cwd;
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

my $show_stat_info = 0;
my $global_should_echo = 0;

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();

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
    if ($line =~ m=^(.*?)(((/\*.*\*/\s*)*(//.*))|/\*.*\*/)?$=m) {
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
  $$filestr_ref =~ s|(<$h+>)|&encode_strings1($1)|eg;
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
  if ($str =~ m/^$bid$/) {
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
sub encode_char { my ($char) = @_; return sprintf("%02x", ord($char)); }
sub dk_mangle {
  my ($symbol) = @_;
  # remove \ preceeding |
  $symbol =~ s/\\\|/\|/g;
  my $fix = 1;
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
    &dakota::util::add_last($ident_symbol, $part);
  }
  my $legal_last_chars = { '?' => 1, '!' => 1 };
  if ($num_encoded && ! (1 == $num_encoded && $$legal_last_chars{$last_encoded_char})) {
    if (1) {
      &dakota::util::add_first($ident_symbol, '_');
      &dakota::util::add_last( $ident_symbol, '_');
    } else {
      &dakota::util::add_first($ident_symbol, &encode_char('|'));
      &dakota::util::add_last( $ident_symbol, &encode_char('|'));
    }
  }
  &dakota::util::add_first($ident_symbol, '_');
  &dakota::util::add_last( $ident_symbol, '_');
  my $value = &ct($ident_symbol);
  return $value;
}
sub dk_mangle_seq {
  my ($seq) = @_;
  my $ident_symbols = [map { &dk_mangle($_) } @$seq];
  return &ct($ident_symbols);
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
# literal symbol/keyword grammar: ^_* ... _*$
# interior only chars: - : . /
# last only chars: ? !
sub ident_regex {
  my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
  my $mid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!])/x; # method ident
 #my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x; # bool   ident
  my $bid = qr/[\w-]+\??/x; # bool   ident
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
my $implicit_metaklass_stmts = qr/( *klass\s+(((klass|trait|superklass)\s+[\w:-]+)|(slots|method|initialize|finalize)).*)/s;
sub rewrite_metaklass_stmts {
  my ($stmts) = @_;
  my $result = $stmts;
  $result =~ s/klass\s+(klass     \s+[\w:-]+)/$1/x;
  $result =~ s/klass\s+(trait     \s+[\w:-]+)/$1/gx;
  $result =~ s/klass\s+(superklass\s+[\w:-]+)/$1/x;
  $result =~ s/klass\s+(slots)               /$1/x;
  $result =~ s/klass\s+(method)              /$1/gx;
  $result =~ s/klass\s+(initialize)          /$1/gx;
  $result =~ s/klass\s+(finalize)            /$1/gx;
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
  &dakota::util::remove_last($parts);
  my $dir = join '/', @$parts;
  return $dir;
}
sub make_dir {
  my ($path, $should_echo) = @_;
  $path = join('/', @$path) if 'ARRAY' eq ref($path);
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

# 1. cmd line
# 2. environment
# 3. config file
# 4. compile-time default

sub var {
  my ($compiler, $lhs, $default_rhs) = @_;
  my $result = &var_array($compiler, $lhs, $default_rhs);
  if ('ARRAY' eq ref($result)) {
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
sub parameter_types_str {
  my ($parameter_types) = @_;
  my $strs = [];
  foreach my $type (@$parameter_types) {
    &add_last($strs, &str_from_seq($type));
  }
  my $result = join(',', @$strs);
  return $result;
}
# [ name, fixed-parameter-types ]
# [ [ x :: signal ], [ object-t, int64-t, ... ] ]
sub kw_args_generics_sig {
  my ($generic) = @_;
  my $keyword_types_len = 0;
  if ($$generic{'kw-args-names'} && 0 < scalar @{$$generic{'kw-args-names'}}) {
    $keyword_types_len = scalar @{$$generic{'kw-args-names'}};
  }
  my $parameter_types = &deep_copy($$generic{'parameter-types'});
  my $offset = scalar @$parameter_types - $keyword_types_len;
  my $keyword_types = [splice @$parameter_types, 0, $offset];
  &add_last($keyword_types, ['...']);
  return ($$generic{'name'}, $keyword_types);
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
  return $global_project;
}
my $global_project_ast;
sub global_project_ast {
  return $global_project_ast;
}
sub set_global_project_ast {
  my ($project_ast_path) = @_;
  $global_project_ast = &scalar_from_file($project_ast_path);
  return $global_project_ast;
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
my $skip_project_io_all_write = 1;
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
  my $num_args = @{$$method{'parameter-types'}};

  if ('va-list-t' eq &ct($$method{'parameter-types'}[-1])) {
    return 1;
  } else {
    return 0;
  }
}
sub is_kw_args_generic {
  my ($generic) = @_;
  my $state = 0;
  my $names =
    {};
    #{ 'init' => 1, 'va::init' => 1, 'append' => 1, 'va::append' => 1, 'print-format' => 1, 'va::print-format' => 1 };

  my ($name, $types) = &kw_args_generics_sig($generic);
  my $name_str =  &str_from_seq($name);
  my $types_str = &parameter_types_str($types);
  my $global_project_ast = &global_project_ast();
  my $tbl = $$global_project_ast{'kw-args-generics'};

  if (exists $$tbl{$name_str} && exists $$tbl{$name_str}{$types_str}) {
    $state = 1;
    if ($$names{$name_str}) {
      print "$name_str: yes\n";
    }
  } else {
    if ($$names{$name_str}) {
      print "$name_str: no\n";
    }
  }
  if (defined $$generic{'kw-args-names'} && 0 < @{$$generic{'kw-args-names'}}) {
    $state = 1;
  }
  if (defined $$generic{'keyword-types'} && 0 < @{$$generic{'keyword-types'}}) {
    $state = 1;
  }
  if ($$names{$name_str}) {
    print "$name_str: $state\n";
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
  my ($infile, $outfile, $file_db) = @_;
  if (! -e $infile) {
    my $tmp_infile = &find_library($infile);
    if ($tmp_infile) {
      $infile = $tmp_infile;
    }
  }
  my $infile_stat =  &path_stat($file_db, $infile,  '--inputs');
  my $outfile_stat = &path_stat($file_db, $outfile, '--output');

  if (!$$infile_stat{'mtime'}) {
    die $0 . ': warning: no-such-file: ' . $infile . ' on which ' . $outfile . ' depends' . $nl;
  }
  if (!$$outfile_stat{'mtime'}) {
    return 1;
  }
  if ($$outfile_stat{'mtime'} < $$infile_stat{'mtime'}) {
    return 1;
  }
  return 0;
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
sub rel_path_canon {
  my ($path1, $cwd) = @_;
  my $result = $path1;

  #if ($path1 =~ m/\.\./g) {
    if (!$cwd) {
      $cwd = &cwd();
    }

    my $path2 = $path1;
    if (&use_abs_path()) {
      $path2 = &Cwd::abs_path($path2);
    }
    Carp::confess("ERROR: cwd=$cwd, path1=$path1, path2=$path2\n") if (!$cwd || !$path2);
    my $common_prefix = &longest_common_prefix($cwd, $path2);
    my $adj_common_prefix = $common_prefix;
    $adj_common_prefix =~ s|/[^/]+/$||g;
    $result = $path2;
    $result =~ s|^$adj_common_prefix/||;

    if ($ENV{'DKT-DEBUG'}) {
      print "$path1 = arg\n";
      print "$cwd = cwd\n";
      print $nl;
      print "$path1 = $path1\n";
      print "$result = $path1\n";
      print "$result = result\n";
    }
  #}
  return $result;
}
sub all_files {
  my ($dirs, $include_regex, $exclude_regex) = @_;
  if ('ARRAY' ne ref($dirs)) {
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
        push @$dirs, $leaf;
        &all_files_recursive($dirs, $include_regex, $exclude_regex, $files);
        pop @$dirs; # remove $leaf
      } elsif (-e $path) {
        if (!defined $include_regex || $path =~ m{$include_regex}) {
          if (!defined $exclude_regex || $path !~ m{$exclude_regex}) {
            my $rel_path_dir = &rel_path_canon($dir);
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
sub clean_paths {
  my ($in, $key) = @_;
  die if !defined $in;
  if ($key && !exists $$in{$key}) {
    die &Dumper($in);
  }
  my $elements_in = $in;
  if ($key) {
    $elements_in = $$in{$key};
  }
  my $elements = [map { &canon_path($_) } @$elements_in];
  $elements = &copy_no_dups($elements);
  if ($key) {
    $$in{$key} = $elements;
  }
  return $elements;
}
sub copy_no_dups {
  my ($strs) = @_;
  my $cmd_info = &root_cmd();
  my $str_set = {};
  my $result = [];
  foreach my $str (@$strs) {
    if (! $$cmd_info{'opts'}{'precompile'} && ! -e $str) {
      if ($str eq &find_library($str)) {
        print STDERR $0 . ': warning: no-such-file: ' . $str . $nl;
      }
    }
    if (&is_abs($str)) {
      $str = &canon_path($str);
    } else {
      $str = &relpath($str);
    }
    if (!$$str_set{$str}) {
      push @$result, $str;
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
  if (!$project) {
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
sub remove_name_va_scope {
  my ($method) = @_;
  #die if 'va' ne $$method{'name'}[0];
  #die if 'va-list-t' ne $$method{'parameter-types'}[-1];
  if (3 == scalar @{$$method{'name'}} && 'va' eq $$method{'name'}[0] && '::' eq $$method{'name'}[1]) {
    &remove_first($$method{'name'});
    &remove_first($$method{'name'});
  }
  else { print "not-va-method: " . &Dumper($method); }
}
sub add_first {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             unshift @$seq, $element; return;
}
sub add_last {
  my ($seq, $element) = @_; if (!defined $seq) { die __FILE__, ":", __LINE__, ": error:\n"; }             push    @$seq, $element; return;
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
  my $old_last = &dakota::util::remove_last($seq);
  &dakota::util::add_last($seq, $element);
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
sub filestr_to_file {
  my ($filestr, $file, $should_echo) = @_;
  my $file_md5 = "$file.md5";
  my $filestr_sig = &digsig($filestr);
  if (1) {
    &write_filestr_to_file($filestr,     $file);
    print STDERR '_output_  ' . $filestr_sig . '  ' . $file . $nl if $should_echo;
    &write_filestr_to_file($filestr_sig, $file_md5);
  }
}
sub scalar_to_file {
  my ($file, $ref) = @_;
  if (!defined $ref) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_to_file(\"$file\", $ref)\n";
  }
  my $refstr = &Dumper($ref);
  &filestr_to_file($refstr, $file);
}
sub scalar_from_file {
  my ($file) = @_;
  die if ! -e $file;
  my $filestr = &filestr_from_file($file);
  my $result = eval $filestr;

  if (!defined $result) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_from_file(\"$file\")\n";
    print STDERR "<" . $filestr . ">" . $nl;
  }
  return $result;
}
sub filestr_from_file {
  my ($file) = @_;
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
unless (caller) {
  &start(\@ARGV);
}
1;
