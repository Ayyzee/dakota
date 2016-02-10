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

BEGIN {
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

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
                 clean_paths
                 cpp_directives
                 decode_comments
                 decode_strings
                 deep_copy
                 dqstr_regex
                 encode_char
                 encode_comments
                 encode_strings
                 filestr_from_file
                 first
                 flatten
                 header_file_regex
                 ident_regex
                 is_symbol_candidate
                 is_debug
                 is_kw_args_generic
                 kw_args_generics
                 kw_args_generics_sig
                 kw_args_placeholders
                 last
                 dk_mangle_seq
                 dk_mangle
                 max
                 method_sig_regex
                 method_sig_type_regex
                 min
                 mtime
                 needs_hex_encoding
                 objdir
                 pann
                 parameter_types_str
                 remove_extra_whitespace
                 remove_first
                 remove_last
                 remove_non_newlines
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
                 global_project_rep
                 set_global_project_rep
              );
use Cwd;
use File::Spec;
use Fcntl qw(:DEFAULT :flock);

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();

my $ENCODED_COMMENT_BEGIN = 'ENCODEDCOMMENTBEGIN';
my $ENCODED_COMMENT_END =   'ENCODEDCOMMENTEND';

my $ENCODED_STRING_BEGIN = 'ENCODEDSTRINGBEGIN';
my $ENCODED_STRING_END =   'ENCODEDSTRINGEND';

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
      $$tbl{'src'} .= $1 . "\n";
      if ($2) {
        $$tbl{'src-comments'} .= $2;
      }
      $$tbl{'src-comments'} .= "\n";
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
  #  print "warning: mend: src-lines = " . scalar(@$src_lines) . ", src-comment-lines = " . scalar(@$src_comment_lines) . "\n";
  #}
  for (my $i = 0; $i < scalar(@$src_lines); $i++) {
    $result .= $$src_lines[$i];
    if (defined $$src_comment_lines[$i]) {
      $result .= $$src_comment_lines[$i];
    }
    $result .= "\n";
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
  my $h  = &header_file_regex();
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
  $str =~ s|(\w)\s+(\w)|$1__WHITESPACE__$2|g;
  $str =~ s|\s+||g;
  $str =~ s|__WHITESPACE__| |g;
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
  if ($str =~ m|^[\w./:-]+$|) {
    return 1;
  } else {
    return 0;
  }
}
sub encode_char { my ($char) = @_; return sprintf("%02x", ord($char)); }
sub dk_mangle {
  my ($symbol) = @_;
  # swap underscore (_) with dash (-)
  my $rand_str = &rand_str();
  $symbol =~ s/_/$rand_str/g;
  $symbol =~ s/-/_/g;
  $symbol =~ s/$rand_str/-/g;
  my $ident_symbol = [];
  &dakota::util::add_first($ident_symbol, '_');

  my $chars = [split //, $symbol];

  foreach my $char (@$chars) {
    my $part;
    if ($char =~ /\w/) {
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
sub dk_mangle_seq {
  my ($seq) = @_;
  my $ident_symbols = [map { &dk_mangle($_) } @$seq];
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
# literal symbol/keyword grammar: ^_* ... _*$
# interior only chars: - : . /
# last only chars: ? !
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
my $build_vars = {
  'objdir' => 'obj',
};
sub objdir {
  my $project = &global_project();
  my $objdir = $$project{'objdir'};
  $objdir = $$build_vars{'objdir'} if ! $objdir;
  if (-e $objdir && ! -d $objdir) {
    die;
  }
  if (! -e $objdir) {
    mkdir $objdir; # or try make_path in File::Path
  }
  if (! -e "$objdir/-user") {
    mkdir "$objdir/-user";
  }
 return $objdir;
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
sub set_global_project {
  my ($project_path) = @_;
  $global_project = &scalar_from_file($project_path);
  return $global_project;
}
my $global_project_rep;
sub global_project_rep {
  return $global_project_rep;
}
sub set_global_project_rep {
  my ($project_rep_path) = @_;
  $global_project_rep = &scalar_from_file($project_rep_path);
  return $global_project_rep;
}
sub is_kw_args_generic {
  my ($generic) = @_;
  my $state = 0;
  if (exists $$generic{'kw-args-names'} && 0 != scalar @{$$generic{'kw-args-names'}}) {
    return 1;
  }
  my ($name, $types) = &kw_args_generics_sig($generic);
  my $name_str =  &str_from_seq($name);
  my $types_str = &parameter_types_str($types);
  my $global_project_rep = &global_project_rep();
  my $tbl = $$global_project_rep{'kw-args-generics'};

  #if (exists $$tbl{$name_str}) { # changechange: 2/2
  if (exists $$tbl{$name_str} && exists $$tbl{$name_str}{$types_str}) {

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
sub flatten {
    my ($a_of_a) = @_;
    my $a = [map {@$_} @$a_of_a];
    return $a;
}
sub clean_paths {
  my ($in, $key) = @_;
  if ($key && !$$in{$key}) {
    return undef;
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
  my $str_set = {};
  my $result = [];
  foreach my $str (@$strs) {
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
sub is_abs {
  my ($path) = @_;
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
  $path = &realpath($path);
  if ($base) {
    $base = &realpath($base);
  }
  my $result = File::Spec->abs2rel($path, $base); # base is optional
  return $result;
}
sub canonpath {
  my ($path) = @_;
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
    $name =~ s|^(.+?)\.$ext_re$|$1|;
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
sub scalar_to_file {
  my ($file, $ref, $original_state) = @_;
  if (!defined $ref) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_to_file($ref)\n";
  }
  my $refstr = &Dumper($ref);
  if (!$original_state) {
    $refstr =~ s/($main::seq)/&unwrap_seq($1)/ges; # unwrap sequences so they are only one line long (or one long line) :-)
  }
  open(FILE, ">", $file) or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
  flock FILE, 2; # LOCK_EX
  truncate FILE, 0;
  print FILE
    '# -*- mode: cperl -*-' . "\n" .
    '# -*- cperl-close-paren-offset: -2 -*-' . "\n" .
    '# -*- cperl-continued-statement-offset: 2 -*-' . "\n" .
    '# -*- cperl-indent-level: 2 -*-' . "\n" .
    '# -*- cperl-indent-parens-as-block: t -*-' . "\n" .
    '# -*- cperl-tab-always-indent: t -*-' . "\n" .
    "\n";
  print FILE $refstr;
  close FILE or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
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
