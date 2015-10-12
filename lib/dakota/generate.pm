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

package dakota::generate;

use strict;
use warnings;

my $should_write_pre_output = 1;
my $gbl_ann_interval = 30;

my $emacs_mode_file_variables = '-*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-';

my $gbl_prefix;
my $gbl_compiler;
my $objdir;
my $dkhh_ext;
my $dkcc_ext;
my $hh_ext;
my $cc_ext;

sub dk_prefix {
  my ($path) = @_;
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
  unshift @INC, "$gbl_prefix/lib";
  $gbl_compiler = do "$gbl_prefix/lib/dakota/compiler.json"
    or die "do $gbl_prefix/lib/dakota/compiler.json failed: $!\n";
  my $platform = do "$gbl_prefix/lib/dakota/platform.json"
    or die "do $gbl_prefix/lib/dakota/platform.json failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $objdir = &dakota::util::objdir();
  $hh_ext = &dakota::util::var($gbl_compiler, 'hh_ext', undef);
  $cc_ext = &dakota::util::var($gbl_compiler, 'cc_ext', undef);
  $dkhh_ext = &dakota::util::var($gbl_compiler, 'dkhh_ext', undef);
  $dkcc_ext = &dakota::util::var($gbl_compiler, 'dkcc_ext', undef);
};
use dakota::rewrite;
use dakota::macro_system;
use dakota::util;

#use Carp;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use integer;
use Cwd;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 empty_klass_defns
                 function::overloadsig
                 generate_nrt_decl
                 generate_nrt_defn
                 generate_rt_decl
                 generate_rt_defn
                 global_scratch_str_ref
                 set_global_scratch_str_ref
                 should_use_include
              );

my $colon = ':'; # key/element delim only
my $kw_args_placeholders = &kw_args_placeholders();
my ($id,  $mid,  $bid,  $tid,
    $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();

my $global_is_defn = undef;     # klass decl vs defn
my $global_is_rt = undef; # <klass>--klasses.{h,cc} vs lib/libdakota--klasses.{h,cc}

my $gbl_nrt_file = undef;
my $global_scratch_str_ref;
#my $global_nrt_cc_str;

my $global_seq_super_t   = [ 'super-t' ]; # special (used in eq compare)
my $global_seq_ellipsis  = [ '...' ];
my $global_klass_defns = [];

my $plural_from_singular = { 'klass', => 'klasses', 'trait' => 'traits' };

# not used. left over (converted) from old code gen model
sub src_path {
  my ($name, $ext) = @_;
  if ($ENV{'DK_ABS_PATH'}) {
    my $cwd = &getcwd();
    return "$cwd/$objdir/$name.$ext";
  } else {
    return "$objdir/$name.$ext";
  }
}
sub empty_klass_defns {
  $global_klass_defns = [];
}
sub global_scratch_str_ref {
  return $global_scratch_str_ref;
}
sub set_global_scratch_str_ref {
  my ($ref) = @_;
  $global_scratch_str_ref = $ref;
}
sub set_nrt_decl() {
  $global_is_rt   = 0;
  $global_is_defn = 0;
}
sub set_nrt_defn() {
  $global_is_rt   = 0;
  $global_is_defn = 1;
}
sub set_rt_decl() {
  $global_is_rt   = 1;
  $global_is_defn = 0;
}
sub set_rt_defn() {
  $global_is_rt   = 1;
  $global_is_defn = 1;
}
sub is_nrt_decl {
  if (!$global_is_rt && !$global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_nrt_defn {
  if (!$global_is_rt && $global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_rt_decl {
  if ($global_is_rt && !$global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_rt_defn {
  if ($global_is_rt && $global_is_defn) {
    return 1;
  } else {
    return 0;
  }
}
sub is_nrt {
  if (!$global_is_rt) {
    return 1;
  } else {
    return 0;
  }
}
sub is_rt {
  if ($global_is_rt) {
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
sub write_to_file_strings {
  my ($path, $strings) = @_;
  my $kw_args_generics = &dakota::util::kw_args_generics();
  open PATH, ">$path" or die __FILE__, ":", __LINE__, ": error: \"$path\" $!\n";
  foreach my $string (@$strings) {
    print PATH $string;
  }
  close PATH;
}
my $gbl_macros;
sub write_to_file_converted_strings {
  my ($path, $strings, $remove) = @_;
  if (!defined $gbl_macros) {
    if ($ENV{'DK_MACROS_PATH'}) {
      $gbl_macros = do $ENV{'DK_MACROS_PATH'} or die "do $ENV{'DK_MACROS_PATH'} failed: $!\n";
    } elsif ($gbl_prefix) {
      $gbl_macros = do "$gbl_prefix/lib/dakota/macros.pl" or die "do $gbl_prefix/lib/dakota/macros.pl failed: $!\n";
    } else {
      die;
    }
  }
  my $kw_args_generics = &dakota::util::kw_args_generics();
  if (defined $path) {
    open PATH, ">$path" or die __FILE__, ":", __LINE__, ": error: \"$path\" $!\n";
  } else {
    *PATH = *STDOUT;
  }
  my $filestr = '';

  foreach my $string (@$strings) {
    $filestr .= $string;
  }
  my $sst = &sst::make($filestr, ">$path");
  if (0) {
    &dakota::macro_system::macros_expand($sst, $gbl_macros, $kw_args_generics);
  }
  my $converted_string = &sst_fragment::filestr($$sst{'tokens'});
  &dakota::rewrite::convert_dk_to_cc(\$converted_string, $kw_args_generics, $remove);

  print PATH $converted_string;

  if (defined $path) {
    close PATH;
  }
}
sub generate_nrt_decl {
  my ($path, $file) = @_;
  &set_nrt_decl();
  return &generate_nrt($path, $file);
}
sub generate_nrt_defn {
  my ($path, $file) = @_;
  &set_nrt_defn();
  return &generate_nrt($path, $file);
}
sub generate_nrt {
  my ($path, $file) = @_;
  my ($dir, $name) = &split_path($path, "\.$id"); # only $cc_ext?
  $gbl_nrt_file = &canon_path("$name.dk");

  my ($generics, $symbols) = &generics::parse($file);
  my $result;

  if (&is_nrt_decl()) {
    my $pre_output = "$dir/$name.$dkhh_ext";
    my $output =     "$dir/$name.$hh_ext";
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output = $ENV{'DKT_DIR'} . '/' . $output
    }
    print "    creating $output" . &pann(__FILE__, __LINE__) . "\n"; # nrt-hh
    $result = &generate_decl_defn($file, $generics, $symbols, 'hh');

    my $str_hh = '// ' . $emacs_mode_file_variables  . "\n";
    $str_hh .= &labeled_src_str(undef, "nrt-hh");
    $str_hh .=
      "\n" .
      &labeled_src_str($result, "headers-hh") .
      &include_dakota_decl_hh() .
      &labeled_src_str($result, "klasses-hh") .
      &labeled_src_str($result, "symbols-hh") .
      &labeled_src_str($result, "strings-hh") .
      &labeled_src_str($result, "hashes-hh") .
      &labeled_src_str($result, "keywords-hh") .
      &labeled_src_str($result, "selectors-hh") .
      &labeled_src_str($result, "signatures-hh") .
      &labeled_src_str($result, "generics-hh");
      #&labeled_src_str($result, "selectors-seq-hh") .
      #&labeled_src_str($result, "signatures-seq-hh") .

    if ($should_write_pre_output) {
      &write_to_file_strings($pre_output, [ $str_hh ]); # generated $objdir/nrt/%.$dkhh_ext
    }
    &write_to_file_converted_strings($output, [ $str_hh ]);
    return "$dir/$name.$hh_ext";
  } else {
    my $pre_output = "$dir/$name.$dkcc_ext";
    my $output =     "$dir/$name.$cc_ext";
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output = $ENV{'DKT_DIR'} . '/' . $output
    }
    print "    creating $output" . &pann(__FILE__, __LINE__) . "\n"; # nrt-cc
    $result = &generate_decl_defn($file, $generics, $symbols, 'cc');

    my $str_cc = '// ' . $emacs_mode_file_variables  . "\n";
    $str_cc .= &labeled_src_str(undef, "nrt-cc");
    $str_cc .=
      "\n" .
      "#include \"$name.$hh_ext\"\n" .
      "\n" .
      "#include \"../$name.$cc_ext\"\n" . # user-code (converted from dk to cc)
      "\n" .
      &dk_generate_cc_footer($file, [], ''); # $file, $stack, $col

    if ($should_write_pre_output) {
      &write_to_file_strings($pre_output, [ $str_cc ]); # generated $objdir/nrt/%.$dkcc_ext
    }
    &write_to_file_converted_strings($output, [ $str_cc ]);
    return $output;
  }
} # sub generate_nrt
sub generate_rt_decl {
  my ($path, $file) = @_;
  &set_rt_decl();
  return &generate_rt($path, $file);
}
sub generate_rt_defn {
  my ($path, $file) = @_;
  &set_rt_defn();
  return &generate_rt($path, $file);
}
sub generate_rt {
  my ($path, $file) = @_;
  my ($dir, $name) = &split_path($path, "\.$id"); # only $cc_ext?
  $gbl_nrt_file = undef;

  my ($generics, $symbols) = &generics::parse($file);
  my $result;

  if (&is_rt_decl()) {
    my $pre_output = "$dir/$name.$dkhh_ext";
    my $output =     "$dir/$name.$hh_ext";
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output = $ENV{'DKT_DIR'} . '/' . $output
    }
    print "    creating $output" . &pann(__FILE__, __LINE__) . "\n"; # rt-hh
    $result = &generate_decl_defn($file, $generics, $symbols, 'hh');

    my $str_hh = '// ' . $emacs_mode_file_variables  . "\n";
    $str_hh .= &labeled_src_str(undef, "rt-hh");
    $str_hh .=
      "\n" .
      &labeled_src_str($result, "headers-hh") .
      &include_dakota_decl_hh() .
      &labeled_src_str($result, "klasses-hh") .
      &labeled_src_str($result, "symbols-hh") .
      &labeled_src_str($result, "strings-hh") .
      &labeled_src_str($result, "hashes-hh") .
      &labeled_src_str($result, "keywords-hh") .
      &labeled_src_str($result, "selectors-hh") .
      &labeled_src_str($result, "signatures-hh") .
      &labeled_src_str($result, "generics-hh");
      #&labeled_src_str($result, "selectors-seq-hh") .
      #&labeled_src_str($result, "signatures-seq-hh") .

    if ($should_write_pre_output) {
      &write_to_file_strings($pre_output, [ $str_hh ]); # generated $objdir/rt/%.$dkhh_ext
    }
    &write_to_file_converted_strings($output, [ $str_hh ]);
    print "    creating $output ... done" . &pann(__FILE__, __LINE__) . "\n"; # rt-hh
    return "$dir/$name.$hh_ext";
  } else {
    my $pre_output = "$dir/$name.$dkcc_ext";
    my $output =     "$dir/$name.$cc_ext";
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output = $ENV{'DKT_DIR'} . '/' . $output
    }
    print "    creating $output" . &pann(__FILE__, __LINE__) . "\n"; # rt-cc
    $result = &generate_decl_defn($file, $generics, $symbols, 'cc');

    my $str_cc = '// ' . $emacs_mode_file_variables  . "\n";
    $str_cc .= &labeled_src_str(undef, "rt-cc");
    $str_cc .=
      "\n" .
      "#include \"$name.$hh_ext\"\n" .
      "\n" .
      &labeled_src_str($result, "symbols-cc") .
      &labeled_src_str($result, "strings-cc") .
      &labeled_src_str($result, "hashes-cc") .
      &labeled_src_str($result, "keywords-cc") .
      &labeled_src_str($result, "klasses-cc") .
      &labeled_src_str($result, "selectors-cc") .
      &labeled_src_str($result, "signatures-cc") .
      &labeled_src_str($result, "generics-cc") .

      &labeled_src_str($result, "selectors-seq-cc") .
      &labeled_src_str($result, "signatures-seq-cc") .

      &generate_defn_footer($file);

    if ($should_write_pre_output) {
      &write_to_file_strings($pre_output, [ $str_cc ]); # generated $objdir/rt/%.$dkcc_ext
    }
    &write_to_file_converted_strings($output, [ $str_cc ]);
    print "    creating $output ... done" . &pann(__FILE__, __LINE__) . "\n"; # rt-cc
    return $output;
  }
} # sub generate_rt
sub labeled_src_str {
  my ($tbl, $key) = @_;
  my $str;
  if (! $tbl) {
    $str = "//==$key==\n";
  } else {
    $str = "//--$key--\n";
    $str .= $$tbl{$key};
    if (!exists $$tbl{$key}) {
      print STDERR "NO SUCH KEY $key\n";
    }
    $str .= "//--$key-end--\n";
  }
  return $str;
}
my $gbl_col_width = '  ';
sub colin {
  my ($col) = @_;
  my $len = length($col)/length($gbl_col_width);
  #print STDERR "$len" . "++\n";
  $len++;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub colout {
  my ($col) = @_;
  &confess("Aborted because of &colout(0)") if '' eq $col;
  my $len = length($col)/length($gbl_col_width);
  #print STDERR "$len" . "--\n";
  $len--;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub generate_decl_defn {
  my ($file, $generics, $symbols, $suffix) = @_;
  my $result = {};
  my $ordered_klass_names = &order_klasses($file);

  $$result{"headers-hh"} =             &linkage_unit::generate_headers(        $file, $ordered_klass_names);
  $$result{"symbols-$suffix"} =        &linkage_unit::generate_symbols(        $file, $generics, $symbols);
  $$result{"strings-$suffix"} =        &linkage_unit::generate_strings(        $file, $generics, $symbols);
  $$result{"hashes-$suffix"} =         &linkage_unit::generate_hashes(         $file, $generics, $symbols);
  $$result{"keywords-$suffix"} =       &linkage_unit::generate_keywords(       $file, $generics, $symbols);
  $$result{"selectors-$suffix"} =      &linkage_unit::generate_selectors(      $file, $generics);
  $$result{"signatures-$suffix"} =     &linkage_unit::generate_signatures(     $file, $generics);
  $$result{"generics-$suffix"} =       &linkage_unit::generate_generics(       $file, $generics);
  $$result{"selectors-seq-$suffix"} =  &linkage_unit::generate_selectors_seq(  $file, $generics);
  $$result{"signatures-seq-$suffix"} = &linkage_unit::generate_signatures_seq( $file, $generics);

  my $col; my $klass_path;
  $$result{"klasses-$suffix"} =        &linkage_unit::generate_klasses(        $file, $col = '', $klass_path = [], $ordered_klass_names);

  return $result;
} # generate_decl_defn
sub generate_defn_footer {
  my ($file) = @_;
  my $rt_cc_str = '';
  my $col = '';
  my $stack = [];
  my $tbl = {
             'imported-klasses' => {},
             'klasses' =>          {},
            };
  &dk_generate_imported_klasses_info($file, $stack, $tbl);
  my $keys_count;
  $keys_count = keys %{$$file{'klasses'}};
  if (0 == $keys_count) {
    $rt_cc_str .= $col . "static assoc-node-t* imported-klasses = nullptr;\n";
    $rt_cc_str .= $col . "static symbol-t const* imported-klasses-names = nullptr;\n";
  } else {
    $rt_cc_str .= $col . "static symbol-t imported-klasses-names[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    my $num_klasses = scalar keys %{$$file{'klasses'}};
    foreach my $klass_name (sort keys %{$$file{'klasses'}}) {
      $rt_cc_str .= $col . "$klass_name\::__klass__,\n";
    }
    $rt_cc_str .= $col . "nullptr\n";
    $col = &colout($col);
    $rt_cc_str .= $col . "};\n";
    ###
    $rt_cc_str .= $col . "static assoc-node-t imported-klasses[] = {" . &ann(__FILE__, __LINE__) . " //rw-data\n";
    $col = &colin($col);
    $num_klasses = scalar keys %{$$file{'klasses'}};
    foreach my $klass_name (sort keys %{$$file{'klasses'}}) {
      $rt_cc_str .= $col . "{ cast(uintptr-t)&$klass_name\::klass, nullptr },\n";
    }
    $rt_cc_str .= $col . "{ cast(uintptr-t)nullptr, nullptr }\n";
    $col = &colout($col);
    $rt_cc_str .= $col . "};\n";
  }
  $rt_cc_str .= &dk_generate_cc_footer($file, $stack, $col);
  #$rt_cc_str .= $col . "extern \"C\"\n";
  #$rt_cc_str .= $col . "{\n";
  #$col = &colin($col);

  my $info_tbl = {
                  "\#signatures-va" => 'signatures-va',
                  "\#signatures" => 'signatures',
                  "\#selectors-va" => 'selectors-va',
                  "\#selectors" => 'selectors',
                  "\#imported-klasses-names" => 'imported-klasses-names',
                  "\#imported-klasses" => 'imported-klasses',
                  "\#klass-defns" => 'klass-defns',
                  "\#interposers" => 'interposers',
                  "\#date" => '__DATE__',
                  "\#time" => '__TIME__',
                  "\#file" => '__FILE__',
                  "\#construct" => 'DKT-CONSTRUCT',
                  "\#dir" => 'getcwd(dir, DK-COUNTOF(dir))',
                  "\#name" => 'DKT-NAME',
                  "\#get-segment-data" => 'dkt-get-segment-data',
                 };
  $rt_cc_str .= "\n";
  $rt_cc_str .= "#include <unistd.h>\n";
  $rt_cc_str .= "\n";
  $rt_cc_str .= "static char dir[4096] = \"\";\n";
  #my $col;
  $rt_cc_str .= &generate_info('reg-info', $info_tbl, $col, $$file{'symbols'}, __LINE__);

  $rt_cc_str .= "\n";
  $rt_cc_str .= $col . "static void __initial() {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  $rt_cc_str .=
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','args':[],'context':'%s','name':'%s'\", __func__, \"before\", DKT-NAME);\n" .
    $col . "dkt-register-info(&reg-info);\n" .
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','args':[],'context':'%s','name':'%s'\", __func__, \"after\", DKT-NAME);\n" .
    $col . "return;\n";
  $col = &colout($col);
  $rt_cc_str .= $col . "}\n";
  $rt_cc_str .= $col . "static void __final() {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  $rt_cc_str .=
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','args':[],'context':'%s','name':'%s'\", __func__, \"before\", DKT-NAME);\n" .
    $col . "dkt-deregister-info(&reg-info);\n" .
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','args':[],'context':'%s','name':'%s'\", __func__, \"after\", DKT-NAME);\n" .
    $col . "return;\n";
  $col = &colout($col);
  $rt_cc_str .= $col . "}\n";
  #$col = &colout($col);
  #$rt_cc_str .= $col . "};\n";

  $rt_cc_str .=
    $col . "namespace { struct /* visibility(hidden) */ __ddl_t {" . &ann(__FILE__, __LINE__) . "\n" .
    $col . "  __ddl_t(const __ddl_t&) = default;\n" .
    $col . "  __ddl_t()  { __initial(); }\n" .
    $col . "  ~__ddl_t() { __final();   }\n" .
    $col . "};}\n" .
    $col . "static __ddl_t __ddl = __ddl_t();\n";
  return $rt_cc_str;
}
sub path::add_last {
  my ($stack, $part) = @_;
  if (0 != @$stack) {
    &dakota::util::add_last($stack, '::');
  }
  &dakota::util::add_last($stack, $part);
}
sub path::remove_last {
  my ($stack) = @_;
  &dakota::util::remove_last($stack); # remove $part

  if (0 != @$stack) {
    &dakota::util::remove_last($stack); # remove '::'
  }
}
sub remove_extra_whitespace {
  my ($str) = @_;
  $str =~ s|(\w)\s+(\w)|$1__WHITESPACE__$2|g;
  $str =~ s|\s+||g;
  $str =~ s|__WHITESPACE__| |g;
  return $str;
}
sub arg::type {
  my ($arg) = @_;
  if (!defined $arg) {
    $arg = [ 'void' ];
  }
  my $delim = $";
  $" = ' ';
  $arg = &path::string($arg);
  $" = $delim;
  $arg = &remove_extra_whitespace($arg);
  return $arg;
}
sub arg_type::super {
  my ($arg_type_ref) = @_;
  my $num_args       = @$arg_type_ref;

  my $new_arg_type_ref = &dakota::util::deep_copy($arg_type_ref);

  #if (object-t eq $$new_arg_type_ref[0]) {
  $$new_arg_type_ref[0] = $global_seq_super_t; # replace_first
  #} else {
  #    $$new_arg_type_ref[0] = 'UNKNOWN-T';
  #}
  return $new_arg_type_ref;
}
sub arg_type::va {
  my ($arg_type_ref) = @_;
  my $num_args       = @$arg_type_ref;

  my $new_arg_type_ref = &dakota::util::deep_copy($arg_type_ref);
  # should assert that $$new_arg_type_ref[$num_args - 1] == "va-list-t"
  $$new_arg_type_ref[$num_args - 1] = $global_seq_ellipsis;
  return $new_arg_type_ref;
}
sub arg_type::names {
  my ($arg_type_ref) = @_;
  my $num_args       = @$arg_type_ref;
  my $arg_num        = 0;
  my $arg_names = [];

  if (&path::string($global_seq_super_t) eq  "@{$$arg_type_ref[0]}") {
    $$arg_names[0] = "arg0";    # replace_first
  } else {
    $$arg_names[0] = 'object';  # replace_first
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    if (&path::string($global_seq_ellipsis) eq  "@{$$arg_type_ref[$arg_num]}") {
      $$arg_names[$arg_num] = undef;
    } elsif ("va-list-t" eq "@{$$arg_type_ref[$arg_num]}") {
      $$arg_names[$arg_num] = "args";
    } else {
      $$arg_names[$arg_num] = "arg$arg_num";
    }
  }
  return $arg_names;
}
sub is_exported {
  my ($method) = @_;
  if (exists $$method{'exported?'} && $$method{'exported?'}) {
    return 1;
  } else {
    return 0;
  }
}
sub is_slots {
  my ($method) = @_;
  if ('object-t' ne $$method{'parameter-types'}[0][0]) {
    return 1;
  } else {
    return 0;
  }
}
sub is_box_type {
  my ($type_seq) = @_;
  my $result;
  my $type_str = &path::string($type_seq);

  if ('slots-t*' eq $type_str ||
      'slots-t'  eq $type_str) {
    $result = 1;
  } else {
    $result = 0;
  }
  return $result;
}
sub arg_type::names_unboxed {
  my ($arg_type_ref) = @_;
  my $num_args       = @$arg_type_ref;
  my $arg_num        = 0;
  my $arg_names = [];

  if ('slots-t*' eq "@{$$arg_type_ref[0]}") {
    $$arg_names[0] = 'unbox(object)';
  } elsif ('slots-t' eq "@{$$arg_type_ref[0]}") {
    $$arg_names[0] = '*unbox(object)';
  } else {
    $$arg_names[0] = 'object';
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    if ('slots-t*' eq "@{$$arg_type_ref[$arg_num]}") {
      $$arg_names[$arg_num] = "unbox(arg$arg_num)";
    } elsif ('slots-t' eq "@{$$arg_type_ref[$arg_num]}") {
      $$arg_names[$arg_num] = "*unbox(arg$arg_num)";
    } else {
      $$arg_names[$arg_num] = "arg$arg_num";
    }
  }
  return $arg_names;
}
sub arg_type::list_pair {
  my ($arg_types_ref, $arg_names_ref) = @_;
  my $num_arg_types = @$arg_types_ref;
  my $num_arg_names = @$arg_names_ref;
  my $list          = '';
  my $arg_num;
  my $delim = ''
;
  for ($arg_num = 0; $arg_num < $num_arg_types; $arg_num++) {
    $list .= $delim . &arg::type(${$arg_types_ref}[$arg_num]);
    if (defined ${$arg_names_ref}[$arg_num]) {
      $list .= ' ' . ${$arg_names_ref}[$arg_num];
    }
    $delim = ', ';
  }
  return \$list;
}
# very similiar to arg_type::list_types
# see below
sub arg_type::list_names {
  my ($args_ref) = @_;
  my $num_args   = @$args_ref;
  my $list       = '';
  my $arg_num;
  my $delim = '';

  for ($arg_num = 0; $arg_num < $num_args; $arg_num++) {
    $list .= $delim . $$args_ref[$arg_num];
    $delim = ', ';
  }
  return \$list;
}
# very similiar to arg_type::list_names
# see above
sub arg_type::list_types {
  my ($args_ref) = @_;
  my $num_args   = @$args_ref;
  my $list       = '';
  my $arg_num;
  my $delim = '';

  for ($arg_num = 0; $arg_num < $num_args; $arg_num++) {
    $list .= $delim . &arg::type($$args_ref[$arg_num]);
    $delim = ', ';
  }
  return \$list;
}
sub method::kw_list_types {
  my ($method) = @_;
  my $result = '';
  my $delim = '';
  foreach my $arg (@{$$method{'parameter-types'}}) {
    my $arg_type = &arg::type($arg);

    if ('va-list-t' ne $arg_type) {
      $result .= $delim . $arg_type;
      $delim = ',';
    }
  }
  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    my $kw_arg_type = &arg::type($$kw_arg{'type'});

    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default_placeholder = $$kw_args_placeholders{'default'};
      $result .= ",$kw_arg_type $kw_arg_name:$kw_arg_default_placeholder";
    } else {
      my $kw_arg_nodefault_placeholder = $$kw_args_placeholders{'nodefault'};
      $result .= ",$kw_arg_type $kw_arg_name:$kw_arg_nodefault_placeholder";
    }
  }
  return $result;
}
sub method::list_types {
  my ($method) = @_;
  my $result = '';
  my $delim = '';
  foreach my $arg (@{$$method{'parameter-types'}}) {
    my $arg_type = &arg::type($arg);

    if ('va-list-t' ne $arg_type) {
      $result .= $delim . $arg_type;
      $delim = ', ';
    }
  }
  return $result;
}
sub kw_arg_type::list_types {
  my ($args_ref, $kw_args_ref) = @_;
  my $num_args    = @$args_ref;
  my $num_kw_args = @$kw_args_ref;
  my $list        = '';
  my $arg_num;
  my $delim = '';

  for ($arg_num = 0; $arg_num < $num_args - 1; $arg_num++) {
    $list .= $delim . &arg::type(${$args_ref}[$arg_num]);
    $delim = ', ';
  }

  for ($arg_num = 0; $arg_num < $num_kw_args; $arg_num++) {
    $list .= $delim . &arg::type(${$kw_args_ref}[$arg_num]{type});
    $delim = ', ';
  }
  return \$list;
}
sub klass::va_list_methods {
  my ($klass_scope) = @_;
  my $method;
  my $va_methods_seq = [];

  #foreach $method (sort method::compare values %{$$klass_scope{'methods'}})
  foreach $method (sort method::compare values %{$$klass_scope{'methods'}}, values %{$$klass_scope{'slots-methods'}}) {
    if (&is_va($method)) {
      &dakota::util::add_last($va_methods_seq, $method);
    }
  }
  return $va_methods_seq;
}
sub klass::kw_args_methods {
  my ($klass_scope) = @_;
  my $method;
  my $kw_args_methods_seq = [];

  foreach $method (sort method::compare values %{$$klass_scope{'methods'}}) {
    if ($$method{'keyword-types'}) {
      &dakota::util::add_last($kw_args_methods_seq, $method);
    }
  }
  return $kw_args_methods_seq;
}
sub klass::method_aliases {
  my ($klass_scope) = @_;
  my $method;
  my $method_aliases_seq = [];

  #foreach $method (sort method::compare values %{$$klass_scope{'methods'}})
  foreach $method (sort method::compare values %{$$klass_scope{'methods'}}, values %{$$klass_scope{'slots-methods'}}) {
    if ($$method{'alias'}) {
      &dakota::util::add_last($method_aliases_seq, $method);
    }
  }
  return $method_aliases_seq;
}
# should make seq of tokens and hand off to a output
# routine that knows what can/can-not be immediatly adjacent.
sub function::decl {
  my ($function, $scope) = @_;
  my $function_decl = '';

  my $visibility = '';
  if (&is_exported($function)) {
    $visibility = 'SO-EXPORT ';
  }
  my $func_spec = '';
  if ($$function{'is-inline'}) {
    $func_spec = 'INLINE ';
  }
  my $return_type = &arg::type($$function{'return-type'});
  my ($name, $parameter_types) = &function::overloadsig_parts($function, $scope);
  $function_decl .= $visibility . $func_spec . "$return_type $name($parameter_types);";
  return \$function_decl;
}
sub function::overloadsig_parts {
  my ($function, $scope) = @_;
  my $last_element = $$function{'parameter-types'}[-1];
  my $last_type = &arg::type($last_element);
  my $name = "@{$$function{'name'} ||= []}"; # rnielsenrnielsen hackhack
  #if ($name eq '') { return undef; }
  my $parameter_types = &arg_type::list_types($$function{'parameter-types'});
  return ($name, $$parameter_types);
}
sub function::overloadsig {
  my ($function, $scope) = @_;
  my ($name, $parameter_types) = &function::overloadsig_parts($function, $scope);
  my $function_overloadsig = "$name($parameter_types)";
  return $function_overloadsig;
}
# should test for 'va', '::' AND va-list-t
sub is_va {
  my ($method) = @_;
  my $num_args = @{$$method{'parameter-types'}};

  if ($$method{'is-va'}) {
    return 1;
  } elsif ("va-list-t" eq "@{$$method{'parameter-types'}[$num_args - 1]}") {
    return 1;
  } else {
    return 0;
  }
}
sub method::varargs_from_qual_va_list {
  my ($method) = @_;
  my $new_method = &dakota::util::deep_copy($method);

  if (3 == @{$$new_method{'name'}}) {
    my $va  = &dakota::util::remove_first($$new_method{'name'});
    my $sro = &dakota::util::remove_first($$new_method{'name'});
  }
  if (exists $$new_method{'parameter-types'}) {
    &dakota::util::_replace_last($$new_method{'parameter-types'}, ['...']);
  }
  delete $$new_method{'is-va'};
  return $new_method;
}
sub method::generate_va_method_defn {
  #my ($scope, $va_method) = @_;
  my ($va_method, $scope, $col, $klass_type, $line) = @_;
  my $is_inline  = $$va_method{'is-inline'};

  my $new_arg_types_ref      = $$va_method{'parameter-types'};
  my $new_arg_types_va_ref   = &arg_type::va($new_arg_types_ref);
  my $new_arg_names_ref      = &arg_type::names($new_arg_types_ref);
  my $new_arg_names_va_ref   = &arg_type::names($new_arg_types_va_ref);
  my $new_arg_list_va_ref    = &arg_type::list_pair($new_arg_types_va_ref, $new_arg_names_va_ref);
  my $new_arg_names_list_ref = &arg_type::list_names($new_arg_names_ref);

  my $num_args = @$new_arg_names_va_ref;
  my $return_type = &arg::type($$va_method{'return-type'});
  my $va_method_name;

  #if ($$va_method{'alias'}) {
  #$va_method_name = "@{$$va_method{'alias'}}";
  #}
  #else {
  $va_method_name = "@{$$va_method{'name'}}";
  #}
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($klass_type) {
    $$scratch_str_ref .= $col . $klass_type . " @$scope { METHOD ";
  }
  else {
    $$scratch_str_ref .= $col . "namespace" . " @$scope { GENERIC ";
  }
  my $kw_args_generics = &dakota::util::kw_args_generics();
  if (exists $$kw_args_generics{$va_method_name}) {
    $$scratch_str_ref .= 'sentinel ';
  }
  my $visibility = '';
  if (&is_exported($va_method)) {
    $visibility = 'SO-EXPORT ';
  }
  my $func_spec = '';
  if ($is_inline) {
    $func_spec = 'INLINE ';
  }
  my $scope_va = &dakota::util::deep_copy($scope);
  &dakota::util::add_last($scope_va, '::');
  &dakota::util::add_last($scope_va, 'va');
  $$scratch_str_ref .= $visibility . $func_spec . "$return_type $va_method_name($$new_arg_list_va_ref)";

  if (!$$va_method{'defined?'} || &is_nrt_decl() || &is_rt_decl()) {
    $$scratch_str_ref .= "; }" . &ann(__FILE__, $line) . "\n";
  } elsif ($$va_method{'defined?'} && (&is_rt_defn())) {
    my $name = &dakota::util::last($$va_method{'name'});
    my $va_name = "_func_";
    &dakota::util::_replace_last($$va_method{'name'}, $va_name);
    my $method_type_decl = &method::type_decl($va_method);
    &dakota::util::_replace_last($$va_method{'name'}, $name);
    my $scope_str = &path::string($scope);
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . "\n";
    $col = &colin($col);
    $$scratch_str_ref .=
      $col . "static $method_type_decl = $scope_str\::va::$va_method_name;\n" .
      $col . "va-list-t args;\n" .
      $col . "va-start(args, $$new_arg_names_ref[$num_args - 2]);\n";

    if (defined $$va_method{'return-type'}) {
      $$scratch_str_ref .= $col . "auto result = ";
    } else {
      $$scratch_str_ref .= $col . "";
    }

    $$scratch_str_ref .=
      "$va_name($$new_arg_names_list_ref);\n" .
      $col . "va-end(args);\n";

    if (defined $$va_method{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;\n";
    } else {
      $$scratch_str_ref .= $col . "return;\n";
    }
    $col = &colout($col);
    $$scratch_str_ref .= "}}\n";
  }
}
sub method::compare {
  my $scope;
  my $a_string = &function::overloadsig($a, $scope = []); # the a and b values sometimes
  my $b_string = &function::overloadsig($b, $scope = []); # are missing the 'name' key

  $a_string =~ s/(.*?va-list-t.*?)/ $1/;
  $b_string =~ s/(.*?va-list-t.*?)/ $1/;

  $a_string cmp $b_string;
}
sub symbol::compare {
  $a cmp $b;
}
sub string::compare {
  $a cmp $b;
}
sub property::compare {
  my ($a_key, $a_val) = %$a;
  my ($b_key, $b_val) = %$b;
  $a_key cmp $b_key;
}
sub type_trans {
  my ($arg_type_ref) = @_;
  if (defined $arg_type_ref) {
    my $arg_type = &path::string($arg_type_ref);
  }
  return $arg_type_ref;
}
sub common::print_signature {
  my ($generic, $col, $path) = @_;
  my $new_arg_type = $$generic{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $$new_arg_type_list = &remove_extra_whitespace($$new_arg_type_list);

  my $scratch_str = "";
  if (&is_va($generic)) {
    $scratch_str .= $col . 'namespace va { VA-SIGNATURE ';
  } else {
    $scratch_str .= $col . 'SIGNATURE ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = 'SO-EXPORT ';
  }
  my $generic_name = "@{$$generic{'name'}}";
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . "signature-t const* $generic_name($$new_arg_type_list)";
  if (&is_nrt_decl() || &is_rt_decl()) {
    if (&is_va($generic)) {
      $scratch_str .= '; }' . "\n";
    } else {
      $scratch_str .= ';' . "\n";
    }
  } elsif (&is_rt_defn()) {
    $scratch_str .= ' {' . $in . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);

    my $return_type_str = &arg::type($$generic{'return-type'});
    my $name_str;
    if (&is_va($generic)) {
      $name_str = "va::$generic_name";
    } else {
      $name_str = "$generic_name";
    }
    my $parameter_types_str = $$new_arg_type_list;

    $scratch_str .= $col . "static signature-t const result = { \"$return_type_str\", \"$name_str\", \"$parameter_types_str\" };\n";
    $scratch_str .= $col . "return &result;\n";
    $col = &colout($col);

    if (&is_va($generic)) {
      $scratch_str .= $col . '}}' . "\n";
    } else {
      $scratch_str .= $col . '}' . "\n";
    }
  }
  return $scratch_str;
}
sub common::generate_signature_defns {
  my ($generics, $col) = @_;
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_signature_defns()\n";

  $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach my $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      my $keyword_types = $$generic{'keyword-types'} ||= undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_signature($generic, $col, ['signature', ':', 'va']);
      }
      $$generic{'keyword-types'} = $keyword_types;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";

  if (1) {
    $scratch_str .= "#if 0\n";
    $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);
    foreach my $generic (sort method::compare @$generics) {
      if (&is_va($generic)) {
        my $varargs_generic = &method::varargs_from_qual_va_list($generic);
        my $keyword_types = $$varargs_generic{'keyword-types'} ||= undef;
        #if (!&is_slots($varargs_generic)) {
        $scratch_str .= &common::print_signature($varargs_generic, $col, ['signature']);
        #}
        $$varargs_generic{'keyword-types'} = $keyword_types;
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
    $scratch_str .= "#endif\n";
  } # if ()
  $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach my $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      my $keyword_types = $$generic{'keyword-types'} ||= undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_signature($generic, $col, ['signature']);
      }
      $$generic{'keyword-types'} = $keyword_types;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  return $scratch_str;
}
sub common::print_selector {
  my ($generic, $col, $path) = @_;
  my $new_arg_type = $$generic{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $$new_arg_type_list = &remove_extra_whitespace($$new_arg_type_list);

  my $scratch_str = "";
  if (&is_va($generic)) {
    $scratch_str .= $col . 'namespace va { VA-SELECTOR ';
  } else {
    $scratch_str .= $col . 'SELECTOR ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = 'SO-EXPORT ';
  }
  my $generic_name = "@{$$generic{'name'}}";
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . "selector-t* $generic_name($$new_arg_type_list)";
  if (&is_nrt_decl() || &is_rt_decl()) {
    if (&is_va($generic)) {
      $scratch_str .= '; }' . $in . "\n";
    } else {
        $scratch_str .= ';' . $in . "\n";
    }
  } elsif (&is_rt_defn()) {
    $scratch_str .= ' {' . $in . "\n";
    $col = &colin($col);

    my $return_type_str = &arg::type($$generic{'return-type'});
    my $name_str;
    if (&is_va($generic)) {
      $name_str = "va::$generic_name";
    } else {
      $name_str = "$generic_name";
    }
    my $parameter_types_str = $$new_arg_type_list;
    my $null_selector = 0;

    $scratch_str .= $col . "static selector-t result = $null_selector;\n";
    $scratch_str .= $col . "return &result;\n";
    $col = &colout($col);
    if (&is_va($generic)) {
      $scratch_str .= $col . '}}' . "\n";
    } else {
      $scratch_str .= $col . '}' . "\n";
    }
  }
  return $scratch_str;
}
sub common::generate_selector_defns {
  my ($generics, $col) = @_;
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_selector_defns()\n";

  $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach my $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      my $keyword_types = $$generic{'keyword-types'} ||= undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_selector($generic, $col, ['__selector', '::', 'va']);
      }
      $$generic{'keyword-types'} = $keyword_types;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . "\n";

  if (1) {
    $scratch_str .= "#if 0\n";
    $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);
    foreach my $generic (sort method::compare @$generics) {
      if (&is_va($generic)) {
        my $varargs_generic = &method::varargs_from_qual_va_list($generic);
        my $keyword_types = $$varargs_generic{'keyword-types'} ||= undef;
        if (!&is_slots($generic)) {
          $scratch_str .= &common::print_selector($varargs_generic, $col, ['__selector']);
        }
        $$varargs_generic{'keyword-types'} = $keyword_types;
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . "\n";
    $scratch_str .= "#endif\n";
  } # if ()
  $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach my $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      my $keyword_types = $$generic{'keyword-types'} ||= undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_selector($generic, $col, ['__selector']);
      }
      $$generic{'keyword-types'} = $keyword_types;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . "\n";
  return $scratch_str;
}

my $global_prev_io;
sub va_generics {
  my ($generics, $name) = @_;
  my $va_generics = [];
  my $fa_generics = [];
  foreach my $generic (sort method::compare @$generics) {
    if (!$name || $name eq "@{$$generic{'name'}}") {
      if (&is_va($generic)) {
        &dakota::util::add_last($va_generics, $generic);
      } else {
        &dakota::util::add_last($fa_generics, $generic);
      }
    }
  }
  return ($va_generics, $fa_generics);
}
sub generics::generate_signature_seq {
  my ($generics, $is_inline, $col) = @_;
  my ($va_generics, $fa_generics) = &va_generics($generics, undef);
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_signature_seq()\n";
  my $generic;
  my $i;
  my $return_type = 'signature-t const*';

  if (0 == @$va_generics) {
    $scratch_str .= $col . "static signature-t const* const* signatures-va = nullptr;\n";
  } else {
    $scratch_str .= $col . "static signature-t const* const signatures-va[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    my $max_width = 0;
    foreach $generic (sort method::compare @$va_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      my $pad = ' ' x ($max_width - $width);
      my $name = "@{$$generic{'name'}}";
      $scratch_str .= $col . "(cast(dkt-signature-function-t)cast($method_type) " . $pad . "__signature::va::$name)(),\n";
    }
    $scratch_str .= $col . "nullptr,\n";
    $col = &colout($col);
    $scratch_str .= $col . "};\n";
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static signature-t const* const* signatures = nullptr;\n";
  } else {
    $scratch_str .= $col . "static signature-t const* const signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    my $max_width = 0;
    foreach $generic (sort method::compare @$va_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    $col = &colin($col);
    foreach $generic (@$fa_generics) {
      if (!&is_slots($generic)) {
        my $method_type = &method::type($generic, [ $return_type ]);
        my $width = length($method_type);
        my $pad = ' ' x ($max_width - $width);
        my $name = "@{$$generic{'name'}}";
        my $in = &ident_comment($name);
        $scratch_str .= $col . "(cast(dkt-signature-function-t)cast($method_type) " . $pad . "__signature::$name)()," . $in . "\n";
      }
    }
    $scratch_str .= $col . "nullptr,\n";
    $col = &colout($col);
    $scratch_str .= $col . "};\n";
  }
  return $scratch_str;
}
sub generics::generate_selector_seq {
  my ($generics, $is_inline, $col) = @_;
  my ($va_generics, $fa_generics) = &va_generics($generics, undef);
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_selector_seq()\n";
  my $generic;
  my $i;
  my $return_type = "selector-t*";

  if (0 == @$va_generics) {
    $scratch_str .= $col . "static selector-node-t* selectors-va = nullptr;\n";
  } else {
    $scratch_str .= $col . "static selector-node-t selectors-va[] = {" . &ann(__FILE__, __LINE__) . " //rw-data\n";
    $col = &colin($col);
    my $max_width = 0;
    my $max_name_width = 0;
    foreach $generic (sort method::compare @$va_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }

      my $name = "@{$$generic{'name'}}";
      my $name_width = length($name);
      if ($name_width > $max_name_width) {
        $max_name_width = $name_width;
      }
    }
    foreach $generic (sort method::compare @$va_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      my $pad = ' ' x ($max_width - $width);
      my $name = "@{$$generic{'name'}}";
      my $name_width = length($name);
      my $name_pad = ' ' x ($max_name_width - $name_width);
      $scratch_str .=
        $col . "{ (cast(dkt-selector-function-t)(cast($method_type) " .
        $pad . "__selector::va::$name" . $name_pad . "))(), nullptr },\n";
    }
    $scratch_str .= $col . "{ nullptr, nullptr },\n";
    $col = &colout($col);
    $scratch_str .= $col . "};\n";
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static selector-node-t* selectors = nullptr;\n";
  } else {
    $scratch_str .= $col . "static selector-node-t selectors[] = {" . &ann(__FILE__, __LINE__) . " //rw-data\n";
    $col = &colin($col);
    my $max_width = 0;
    my $max_name_width = 0;
    foreach $generic (@$fa_generics) {
      my $method_type = &method::type($generic, [ $return_type ]);
      my $width = length($method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }

      my $name = "@{$$generic{'name'}}";
      my $name_width = length($name);
      if ($name_width > $max_name_width) {
        $max_name_width = $name_width;
      }
    }
    foreach $generic (@$fa_generics) {
      if (!&is_slots($generic)) {
        my $method_type = &method::type($generic, [ $return_type ]);
        my $width = length($method_type);
        my $pad = ' ' x ($max_width - $width);
        my $name = "@{$$generic{'name'}}";
        my $in = &ident_comment($name);
        my $name_width = length($name);
        my $name_pad = ' ' x ($max_name_width - $name_width);
        $scratch_str .=
          $col . "{ (cast(dkt-selector-function-t)(cast($method_type) " .
          $pad . "__selector::$name" . $name_pad . "))(), nullptr }," . $in . "\n";
      }
    }
    $scratch_str .= $col . "{ nullptr, nullptr },\n";
    $col = &colout($col);
    $scratch_str .= $col . "};\n";
  }
  return $scratch_str;
}
sub generics::generate_va_generic_defns {
  my ($generics, $is_inline, $col) = @_;
  foreach my $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      my $scope = [];
      &path::add_last($scope, 'dk');
      my $new_generic = &dakota::util::deep_copy($generic);
      $$new_generic{'is-inline'} = $is_inline;

      $$new_generic{'defined?'} = 1; # hackhack

      my $klass_type;
      &method::generate_va_method_defn($new_generic, $scope, $col, $klass_type = undef, __LINE__); # object-t
      $$new_generic{'parameter-types'}[0] = $global_seq_super_t; # replace_first
      &method::generate_va_method_defn($new_generic, $scope, $col, $klass_type = undef, __LINE__); # super-t
      &path::remove_last($scope);
    }
  }
}
sub generics::generate_generic_defn {
  my ($generic, $is_inline, $col) = @_;
  my $new_arg_type            = $$generic{'parameter-types'};
  my $new_arg_type_list   = &arg_type::list_types($new_arg_type);
  $new_arg_type            = $$generic{'parameter-types'};

  my $new_arg_names           = &arg_type::names($new_arg_type);
  my $new_arg_list            = &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$generic{'return-type'});
  my $scratch_str_ref = &global_scratch_str_ref();
  if (&is_va($generic)) {
    $$scratch_str_ref .= $col . 'namespace va { VA-GENERIC ';
  } else {
    $$scratch_str_ref .= $col . 'GENERIC ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = 'SO-EXPORT ';
  }
  my $func_spec = '';
  if ($is_inline) {
    $func_spec = 'INLINE ';
  }
  my $generic_name = "@{$$generic{'name'}}";
  my $in = &ident_comment($generic_name);

  $$scratch_str_ref .= $visibility . $func_spec . "$return_type $generic_name($$new_arg_list)";

  if (&is_nrt_decl() || &is_rt_decl()) {
    if (&is_va($generic)) {
      $$scratch_str_ref .= "; }" . &ann(__FILE__, __LINE__) . "\n";
    } else {
      $$scratch_str_ref .= ";" . &ann(__FILE__, __LINE__) . "\n";
    }
  } elsif (&is_rt_defn()) {
    $$scratch_str_ref .= " {" . $in . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);
    if (&is_va($generic)) {
      $$scratch_str_ref .=
        $col . "DEBUG-STMT(static signature-t const* signature = dkt-signature(va::$generic_name($$new_arg_type_list)));\n" .
        $col . "static selector-t selector = selector(va::$generic_name($$new_arg_type_list));\n" .
        $col . "object-t kls = object->klass;\n" .
        $col . "method-t _func_ = klass::unbox(kls)->methods.addrs[selector];\n";
    } else {
      $$scratch_str_ref .=
        $col . "DEBUG-STMT(static signature-t const* signature = dkt-signature($generic_name($$new_arg_type_list)));\n" .
        $col . "static selector-t selector = selector($generic_name($$new_arg_type_list));\n" .
        $col . "object-t kls = object->klass;\n" .
        $col . "method-t _func_ = klass::unbox(kls)->methods.addrs[selector];\n";
    }
    $$scratch_str_ref .= $col . "DEBUG-STMT(if (DKT-NULL-METHOD == _func_)\n";
    $$scratch_str_ref .= $col . "  throw make(no-such-method-exception::klass, \#object $colon object, \#signature $colon signature));\n";
    my $arg_names = &dakota::util::deep_copy(&arg_type::names(&dakota::util::deep_copy($$generic{'parameter-types'})));
    my $arg_names_list = &arg_type::list_names($arg_names);

    if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
      $$scratch_str_ref .= $col . "DKT-TRACE-BEFORE(signature, _func_, $$arg_names_list, nullptr);\n";
    }
    if (defined $$generic{'return-type'}) {
      $$scratch_str_ref .= $col . "$return_type result = ";
    }

    $new_arg_names = &arg_type::names($new_arg_type);

    my $new_arg_names_list = &arg_type::list_names($new_arg_names);

    $$scratch_str_ref .= "(cast($return_type (*)($$new_arg_type_list))_func_)($$new_arg_names_list);\n";
    if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
      my $result = 'result';
      if ($$arg_names_list =~ m/,/) {
        $$arg_names_list =~ s/^(.+?),\s*(.*)$/$1, $result, $2/;
      } else {
        $$arg_names_list .= ", $result";
      }
      $$scratch_str_ref .= $col . "DKT-TRACE-AFTER(signature, _func_, $$arg_names_list, nullptr);\n";
    }

    if (defined $$generic{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;\n";
    } else {
      $$scratch_str_ref .= $col . "return;\n";
    }
    $col = &colout($col);
    if (&is_va($generic)) {
      $$scratch_str_ref .= $col . '}}' . "\n";
    } else {
      $$scratch_str_ref .= $col . '}' . "\n";
    }
  }
}
sub generics::generate_super_generic_defn {
  my ($generic, $is_inline, $col) = @_;
  my $new_arg_type            = $$generic{'parameter-types'};
  my $new_arg_type_list   = &arg_type::list_types($new_arg_type);
  $new_arg_type            = $$generic{'parameter-types'};
  $new_arg_type            = &arg_type::super($new_arg_type);
  my $new_arg_names           = &arg_type::names($new_arg_type);
  my $new_arg_list            = &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$generic{'return-type'});
  my $scratch_str_ref = &global_scratch_str_ref();
  if (&is_va($generic)) {
    $$scratch_str_ref .= $col . 'namespace va { VA-GENERIC ';
  } else {
    $$scratch_str_ref .= $col . 'GENERIC ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = 'SO-EXPORT ';
  }
  my $func_spec = '';
  if ($is_inline) {
    $func_spec = 'INLINE ';
  }
  my $generic_name = "@{$$generic{'name'}}";
  my $in = &ident_comment($generic_name);

  $$scratch_str_ref .= $visibility . $func_spec . "$return_type $generic_name($$new_arg_list)";

  if (&is_nrt_decl() || &is_rt_decl()) {
    if (&is_va($generic)) {
      $$scratch_str_ref .= "; }" . "\n";
    } else {
      $$scratch_str_ref .= ";" . $in . "\n";
    }
  } elsif (&is_rt_defn()) {
    $$scratch_str_ref .= " {" . $in . "\n";
    $col = &colin($col);
    if (&is_va($generic)) {
      $$scratch_str_ref .=
        $col . "DEBUG-STMT(static signature-t const* signature = dkt-signature(va::$generic_name($$new_arg_type_list)));\n" .
        $col . "static selector-t selector = selector(va::$generic_name($$new_arg_type_list));\n" .
        $col . "object-t kls = klass::unbox(arg0.klass)->superklass;\n" .
        $col . "method-t _func_ = klass::unbox(kls)->methods.addrs[selector];\n";
    } else {
      $$scratch_str_ref .=
        $col . "DEBUG-STMT(static signature-t const* signature = dkt-signature($generic_name($$new_arg_type_list)));\n" .
        $col . "static selector-t selector = selector($generic_name($$new_arg_type_list));\n" .
        $col . "object-t kls = klass::unbox(arg0.klass)->superklass;\n" .
        $col . "method-t _func_ = klass::unbox(kls)->methods.addrs[selector];\n";
    }
    $$scratch_str_ref .= $col . "DEBUG-STMT(if (DKT-NULL-METHOD == _func_)\n";
    $$scratch_str_ref .= $col . "  throw make(no-such-method-exception::klass, \#object $colon arg0.self, \#superkls $colon superklass-of(arg0.klass), \#signature $colon signature));\n";
    my $arg_names = &dakota::util::deep_copy(&arg_type::names(&arg_type::super($$generic{'parameter-types'})));
    my $arg_names_list = &arg_type::list_names($arg_names);

    if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
      $$scratch_str_ref .= $col . "DKT-TRACE-BEFORE(signature, _func_, $$arg_names_list, nullptr);\n";
    }
    if (defined $$generic{'return-type'}) {
      $$scratch_str_ref .= $col . "$return_type result = ";
    }

    $new_arg_type = &arg_type::super($new_arg_type);
    $new_arg_names = &arg_type::names($new_arg_type);
    &dakota::util::_replace_first($new_arg_names, "arg0.self");
    my $new_arg_names_list = &arg_type::list_names($new_arg_names);

    $$scratch_str_ref .= "(cast($return_type (*)($$new_arg_type_list))_func_)($$new_arg_names_list);\n";
    if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
      my $result = 'result';
      if ($$arg_names_list =~ m/,/) {
        $$arg_names_list =~ s/^(.+?),\s*(.*)$/$1, $result, $2/;
      } else {
        $$arg_names_list .= ", $result";
      }
      $$scratch_str_ref .= $col . "DKT-TRACE-AFTER(signature, _func_, $$arg_names_list, nullptr);\n";
    }

    if (defined $$generic{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;\n";
    } else {
      $$scratch_str_ref .= $col . "return;\n";
    }
    $col = &colout($col);
    if (&is_va($generic)) {
      $$scratch_str_ref .= $col . '}}' . "\n";
    } else {
      $$scratch_str_ref .= $col . '}' . "\n";
    }
  }
}
sub generics::generate_generic_defns {
  my ($generics, $is_inline, $col) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_generic_defns()\n";
  my $generic;
  #$$scratch_str_ref .= "#if defined DKT-VA-GENERICS\n";
  $$scratch_str_ref .= &labeled_src_str(undef, "generics-va-object-t");
  $$scratch_str_ref .= $col . 'namespace dk {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      if (!&is_slots($generic)) {
        &generics::generate_generic_defn($generic, $is_inline, $col);
      }
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  $$scratch_str_ref .= &labeled_src_str(undef, "generics-va-super-t");
  $$scratch_str_ref .= $col . 'namespace dk {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      if (!&is_slots($generic)) {
        &generics::generate_super_generic_defn($generic, $is_inline, $col);
      }
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  #$$scratch_str_ref .= "#endif // defined DKT-VA-GENERICS\n";
  #if (!&is_slots($generic)) {
  &generics::generate_va_generic_defns($generics, $is_inline = 0, $col);
  #}
  $$scratch_str_ref .= &labeled_src_str(undef, "generics-object-t");
  $$scratch_str_ref .= $col . 'namespace dk {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      if (!&is_slots($generic)) {
        &generics::generate_generic_defn($generic, $is_inline, $col);
      }
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  $$scratch_str_ref .= &labeled_src_str(undef, "generics-super-t");
  $$scratch_str_ref .= $col . 'namespace dk {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  foreach $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      if (!&is_slots($generic)) {
        &generics::generate_super_generic_defn($generic, $is_inline, $col);
      }
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
}
sub linkage_unit::generate_signatures {
  my ($scope, $generics) = @_;
  my $col = '';
  my $scratch_str = "";
  $scratch_str .= &common::generate_signature_defns($generics, $col); # __signature::foobar(...)
  return $scratch_str;
}
sub linkage_unit::generate_signatures_seq {
  my ($scope, $generics) = @_;
  my $col = '';
  my $scratch_str = "";
  if (&is_nrt_defn() || &is_rt_defn()) {
    my $is_inline;
    $scratch_str .= &generics::generate_signature_seq($generics, $is_inline = 0, $col);
  }
  return $scratch_str;
}
sub linkage_unit::generate_selectors {
  my ($scope, $generics) = @_;
  my $col = '';
  my $scratch_str = "";
  $scratch_str .= &common::generate_selector_defns($generics, $col); # __selector::foobar(...)
  return $scratch_str;
}
sub linkage_unit::generate_selectors_seq {
  my ($scope, $generics) = @_;
  my $col = '';
  my $scratch_str = "";
  if (&is_nrt_defn() || &is_rt_defn()) {
    my $is_inline;
    $scratch_str .= &generics::generate_selector_seq($generics, $is_inline = 0, $col);
  }
  return $scratch_str;
}
sub linkage_unit::generate_generics {
  my ($file, $scope) = @_;
  my $col = '';
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  my $is_inline;
  &generics::generate_generic_defns($scope, $is_inline = 0, $col);

  if ($$file{'should-generate-make'}) {
    $$scratch_str_ref .=
      "\n" .
      "#if !defined DK-USE-MAKE-MACRO\n" .
      &generics::generate_va_make_defn($scope, $is_inline = 1, $col) .
      "#endif\n";
  }
  return $$scratch_str_ref;
}
sub generics::generate_va_make_defn {
  my ($generics, $is_inline, $col) = @_;
  my $result = '';
  #$result .= $col . "// generate_va_make_defn()\n";
  $result .= $col . "sentinel object-t make(object-t kls, ...)";
  if (&is_nrt_decl() || &is_rt_decl()) {
    $result .= ";\n";
  } elsif (&is_rt_defn()) {
    my $alloc_type_decl = "object-t (*alloc)(object-t)"; ### should use method::type_decl
    my $init_type_decl =  "object-t (*_func_)(object-t, va-list-t)"; ### should use method::type_decl

    $result .= " {" . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);
    $result .=
      $col . "static $alloc_type_decl = dk::alloc;\n" .
      $col . "static $init_type_decl = dk::va::init;\n" .
      $col . "va-list-t args;\n" .
      $col . "va-start(args, kls);\n" .
      $col . "auto result = alloc(kls);\n" .
      $col . "DKT-VA-TRACE-BEFORE(dkt-signature(va::init(object-t, va-list-t)), cast(method-t)_func_, result, args);\n" .
      $col . "result = _func_(result, args); // init()\n" .
      $col . "DKT-VA-TRACE-AFTER( dkt-signature(va::init(object-t, va-list-t)), cast(method-t)_func_, result, args);\n" .
      $col . "va-end(args);\n" .
      $col . "return result;\n";
    $col = &colout($col);
    $result .= $col . "}\n";
  }
  return $result;
}
sub path::string {
  my ($seq) = @_;
  my $string = "@$seq";
  return $string;
}
## exists()  (does this key exist)
## defined() (is the value (for this key) non-undef)
sub dk_parse {
  my ($dkfile) = @_;            # string.dk
  my $plfile = &dakota::parse::rep_path_from_any_path($dkfile);
  my $file = &dakota::util::scalar_from_file($plfile);
  $file = &dakota::parse::kw_args_translate($file);
  return $file;
}
sub slots_decl {
  my ($slots_scope) = @_;
  my $result = 'slots';
  if ($$slots_scope{'cat'}) {
    if ('struct' ne $$slots_scope{'cat'}) {
      $result .= ' ' . $$slots_scope{'cat'};
    }
    if ('enum' eq $$slots_scope{'cat'}) {
      if ($$slots_scope{'enum-base'}) {
        $result .= ' : ' . $$slots_scope{'enum-base'};
      } else {
        $result .= ' : ' . 'int-t';
      }
    }
  } elsif ($$slots_scope{'type'}) {
    $result .= ' ' . $$slots_scope{'type'};
  }
  return $result;
}
sub generate_struct_or_union_decl {
  my ($col, $slots_scope, $is_exported, $is_slots) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $slots_info = $$slots_scope{'info'};

  if ('struct' eq $$slots_scope{'cat'} ||
      'union'  eq $$slots_scope{'cat'}) {
    $$scratch_str_ref .= ' ' . &slots_decl($slots_scope) . '; ';
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
}
sub generate_struct_or_union_defn {
  my ($col, $slots_scope, $is_exported, $is_slots) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $slots_info = $$slots_scope{'info'};

  if ('struct' eq $$slots_scope{'cat'} ||
      'union'  eq $$slots_scope{'cat'}) {
    $$scratch_str_ref .= ' ' . &slots_decl($slots_scope) . ' {' . &ann(__FILE__, __LINE__) . "\n";
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }

  my $max_width = 0;
  foreach my $slot_info (@$slots_info) {
    my $width = length($$slot_info{'type'});
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $slot_info (@$slots_info) {
    my $width = length($$slot_info{'type'});
    my $pad = ' ' x ($max_width - $width);
    if ($$slot_info{'expr'}) {
      $$scratch_str_ref .= $col . "$$slot_info{'type'} " . $pad . "$$slot_info{'name'} = $$slot_info{'expr'};\n";
    } else {
      $$scratch_str_ref .= $col . "$$slot_info{'type'} " . $pad . "$$slot_info{'name'};\n";
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}';
}
sub generate_enum_decl {
  my ($col, $enum, $is_exported, $is_slots) = @_;
  die if $$enum{'type'} && $is_slots;
  my $info = $$enum{'info'};
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($is_slots) {
    $$scratch_str_ref .= 'slots enum';
  }
  elsif ($$enum{'type'}) {
    $$scratch_str_ref .= 'enum' . @{$$enum{'type'}};
  } else {
    $$scratch_str_ref .= 'enum';
  }
  if ($$enum{'enum-base'}) {
    $$scratch_str_ref .= ' : ' . $$enum{'enum-base'} . ';';
  } else {
    $$scratch_str_ref .= ' : int-t;';
  }
}
sub generate_enum_defn {
  my ($col, $enum, $is_exported, $is_slots) = @_;
  die if $$enum{'type'} && $is_slots;
  my $slots_info = $$enum{'info'};
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($is_slots) {
    $$scratch_str_ref .= 'slots enum';
  }
  elsif ($$enum{'type'}) {
    $$scratch_str_ref .= 'enum' . @{$$enum{'type'}};
  } else {
    $$scratch_str_ref .= 'enum';
  }
  if ($$enum{'enum-base'}) {
    $$scratch_str_ref .= ' : ' . $$enum{'enum-base'};
  } else {
    $$scratch_str_ref .= ' : int-t';
  }
  $$scratch_str_ref .= " {" . &ann(__FILE__, __LINE__) . "\n";
  my $max_width = 0;
  foreach my $slot_info (@$slots_info) {
    my $width = length($$slot_info{'name'});
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $slot_info (@$slots_info) {
    if ($$slot_info{'expr'}) {
      my $width = length($$slot_info{'name'});
      my $pad = ' ' x ($max_width - $width);
      $$scratch_str_ref .= $col . "$$slot_info{'name'} = " . $pad . "$$slot_info{'expr'},\n";
    } else {
      $$scratch_str_ref .= $col . "$$slot_info{'name'},\n";
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}';
}
sub parameter_list_from_slots_info {
  my ($slots_info) = @_;
  my $names = '';
  my $pairs = '';
  my $pairs_w_expr = '';
  my $sep = '';

  foreach my $slot_info (@$slots_info) {
    my $type = $$slot_info{'type'};
    my $name = $$slot_info{'name'};
   #$names .=        "$sep/*.$name =*/ _$name";
    $names .=        "$sep.$name = _$name";
    $pairs .=        "$sep$type _$name";
    $pairs_w_expr .= "$sep$type _$name";
    $sep = ', ';

    if ($$slot_info{'expr'}) {
     #$pairs_w_expr .= " /*= $$slot_info{'expr'}*/";
      $pairs_w_expr .= " = $$slot_info{'expr'}";
    }
  }
  return ($names, $pairs, $pairs_w_expr);
}
sub has_object_method_defn {
  my ($klass_scope, $slots_method_info) = @_;
  my $result = 0;

  my $object_method_info = &convert_to_object_method($slots_method_info);
  my $object_method_sig = &function::overloadsig($object_method_info, []);

  if ($$klass_scope{'methods'}{$object_method_sig} &&
      $$klass_scope{'methods'}{$object_method_sig}{'defined?'}) {
    $result = 1;
  }
  return $result;
}
sub generate_klass_unbox {
  my ($klass_path, $klass_name, $is_klass_defn) = @_;
  my $result = '';
  my $col = '';
  if ($klass_name eq 'object') {
    #$result .= $col . "// special-case: no generated unbox() for klass 'object' due to Koenig lookup\n";
  } elsif ($klass_name eq 'klass') {
    $result .= $col . "klass $klass_name { unbox-attrs slots-t* unbox(object-t object)";

    if (&is_nrt_decl() || &is_rt_decl()) {
      $result .= "; }" . &ann(__FILE__, __LINE__) . " // special-case\n";
    } elsif (&is_rt_defn()) {
      $result .=
        " {" . &ann(__FILE__, __LINE__) . " // special-case\n" .
        $col . "  slots-t* s = cast(slots-t*)(cast(uint8-t*)object + sizeof(object::slots-t));\n" .
        $col . "  return s;\n" .
        $col . "}}\n";
    }
  } else {
    ### unbox() same for all types
    if ($is_klass_defn || (&has_exported_slots() && &has_slots_info())) {
      $result .= $col . "klass $klass_name { unbox-attrs slots-t* unbox(object-t object)";
      if (&is_nrt_decl() || &is_rt_decl()) {
        $result .= "; }" . &ann(__FILE__, __LINE__) . "\n"; # general-case
      } elsif (&is_rt_defn()) {
        $result .=
          " {" . &ann(__FILE__, __LINE__) . "\n" .
          $col . "  DEBUG-STMT(dkt-unbox-check(object, klass)); // optional\n" .
          $col . "  slots-t* s = cast(slots-t*)(cast(uint8-t*)object + klass::unbox(klass)->offset);\n" .
          $col . "  return s;\n" .
          $col . "}}\n";
      }
    }
  }
  return $result;
}
sub generate_klass_box {
  my ($klass_scope, $klass_path, $klass_name) = @_;
  my $result = '';
  my $col = '';

  if ('object' eq &path::string($klass_path)) {
    ### box() non-array-type
    $result .= $col . "klass $klass_name { object-t box(slots-t* arg)";

    if (&is_nrt_decl() || &is_rt_decl()) {
      $result .= "; }" . &ann(__FILE__, __LINE__) . "\n";
    } elsif (&is_rt_defn()) {
      $result .=
        " {" . &ann(__FILE__, __LINE__) . "\n" .
        $col . "  return arg;\n" .
        $col . "}}\n";
    }
  } else {
    if (&has_exported_slots($klass_scope)) {
      ### box()
      if (&is_array_type($$klass_scope{'slots'}{'type'})) {
        ### box() array-type
        $result .= $col . "klass $klass_name { object-t box(slots-t arg)";

        if (&is_nrt_decl() || &is_rt_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . "\n";
        } elsif (&is_rt_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . "\n";
          $col = &colin($col);
          $result .=
            $col . "object-t result = make(klass);\n" .
            $col . "memcpy(*unbox(result), arg, sizeof(slots-t)); // unfortunate\n" .
            $col . "return result;\n";
          $col = &colout($col);
          $result .= $col . "}}\n";
        }
        $result .= $col . "klass $klass_name { object-t box(slots-t* arg)";

        if (&is_nrt_decl() || &is_rt_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . "\n";
        } elsif (&is_rt_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . "\n";
          $col = &colin($col);
          $result .=
            $col . "object-t result = box(*arg);\n" .
            $col . "return result;\n";
          $col = &colout($col);
          $result .= $col . "}}\n";
        }
      } else { # !&is_array_type()
        ### box() non-array-type
        $result .= $col . "klass $klass_name { object-t box(slots-t* arg)";

        if (&is_nrt_decl() || &is_rt_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . "\n";
        } elsif (&is_rt_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . "\n";
          $col = &colin($col);
          $result .=
            $col . "object-t result = make(klass);\n" .
            $col . "*unbox(result) = *arg;\n" .
            $col . "return result;\n";
          $col = &colout($col);
          $result .= $col . "}}\n";
        }
        $result .= $col . "klass $klass_name { object-t box(slots-t arg)";

        if (&is_nrt_decl() || &is_rt_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . "\n";
        } elsif (&is_rt_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . "\n";
          $col = &colin($col);
          $result .=
            $col . "object-t result = box(&arg);\n" .
            $col . "return result;\n";
          $col = &colout($col);
          $result .= $col . "}}\n";
        }
      }
    }
  }
  if ((&is_nrt_decl() || &is_rt_decl) && &has_exported_slots($klass_scope) && &has_slots_type($klass_scope)) {
    $result .= $col . "using $klass_name\::box;" . &ann(__FILE__, __LINE__) . "\n";
  }
  return $result;
}
sub generate_klass_construct {
  my ($klass_scope, $klass_name) = @_;
  my $result = '';
  my $col = '';
  if ($$klass_scope{'slots'}{'cat'} &&
      'struct' eq $$klass_scope{'slots'}{'cat'}) {
    if ($ENV{'DK_NO_COMPOUND_LITERALS'}) {
      if (&has_slots_info($klass_scope)) {
        my ($names, $pairs, $pairs_w_expr) = &parameter_list_from_slots_info($$klass_scope{'slots'}{'info'});
        #print "generate-klass-construct: " . &Dumper($$klass_scope{'slots'}{'info'});

        if ($pairs =~ m/\[/g) {
        } else {
          if (&is_nrt_decl() || &is_rt_decl()) {
            $result .= $col . "klass $klass_name { slots-t construct($pairs_w_expr); }" . &ann(__FILE__, __LINE__) . "\n";
          } elsif (&is_rt_defn()) {
            $result .= $col . "klass $klass_name { slots-t construct($pairs) {" . &ann(__FILE__, __LINE__) . "\n";
            $col = &colin($col);
            $result .=
              $col . "slots-t result = cast(slots-t){ $names };\n" .
              $col . "return result;\n";
            $col = &colout($col);
            $result .= $col . "}}\n";
          }
        }
      }
    }
  }
  return $result;
}
sub linkage_unit::generate_klasses_body {
  my ($klass_scope, $col, $klass_type, $klass_path, $klass_name) = @_;
  my $is_klass_defn = scalar keys %$klass_scope;
  my $va_list_methods = &klass::va_list_methods($klass_scope);
  my $kw_args_methods = &klass::kw_args_methods($klass_scope);
  my $method;

  my $scratch_str_ref = &global_scratch_str_ref();

  if (&is_nrt_decl() || &is_rt_decl()) {
    #$$scratch_str_ref .= $col . "extern symbol-t __type__;\n";
    $$scratch_str_ref .= $col . "$klass_type $klass_name { extern symbol-t __klass__; }" . &ann(__FILE__, __LINE__) . "\n";
  } elsif (&is_rt_defn()) {
    #$$scratch_str_ref .= $col . "symbol-t __type__ = \$$klass_type;\n";
    $$scratch_str_ref .= $col . "$klass_type $klass_name { symbol-t __klass__ = \#@$klass_path; }" . &ann(__FILE__, __LINE__) . "\n";
  }

  if ('klass' eq $klass_type) {
    if (&is_nrt_decl() || &is_rt_decl()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { extern DKT-RODATA-SECTION object-t klass; }" . &ann(__FILE__, __LINE__) . "\n";
    } elsif (&is_rt_defn()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { DKT-RODATA-SECTION object-t klass = nullptr; }" . &ann(__FILE__, __LINE__) . "\n";
    }
    if (!&is_rt_defn()) {
      my $is_exported;
      if (exists $$klass_scope{'const'}) {
        foreach my $const (@{$$klass_scope{'const'}}) {
          $$scratch_str_ref .= $col . "$klass_type $klass_name { extern const $$const{'type'} $$const{'name'}; }" . &ann(__FILE__, __LINE__) . "\n";
        }
      }
    }
    my $object_method_defns = {};
    foreach $method (sort method::compare values %{$$klass_scope{'slots-methods'}}) {
      if (&is_nrt_defn() || &is_rt_defn() || &is_exported($method)) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'parameter-types'}[0])) {
            my $method_decl_ref = &function::decl($method, $klass_path);
            #$$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "REMOVE") . "\n";
            if (!&has_object_method_defn($klass_scope, $method)) {
              my $object_method = &convert_to_object_method($method);
              my $sig = &function::overloadsig($object_method, []);
              if (!$$object_method_defns{$sig}) {
                &generate_object_method_defn($method, $klass_path, $col, $klass_type, __LINE__);
              }
              $$object_method_defns{$sig} = 1;
            }
          }
        }
      } else {
        if (!&is_va($method)) {
          my $method_decl_ref = &function::decl($method, $klass_path);
          $$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "DUPLICATE") . "\n";
          my $object_method = &convert_to_object_method($method);
          my $sig = &function::overloadsig($object_method, []);
          if (!$$object_method_defns{$sig}) {
            &generate_object_method_decl($method, $klass_path, $col, $klass_type, __LINE__);
          }
          $$object_method_defns{$sig} = 1;
        }
      }
    }
    my $exported_slots_methods = &exported_slots_methods($klass_scope);
    foreach $method (sort method::compare values %$exported_slots_methods) {
      die if !&is_exported($method);
      if (&is_nrt_defn() || &is_rt_defn()) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'parameter-types'}[0])) {
            my $method_decl_ref = &function::decl($method, $klass_path);
            $$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__) . "\n";
            if (!&has_object_method_defn($klass_scope, $method)) {
              my $object_method = &convert_to_object_method($method);
              my $sig = &function::overloadsig($object_method, []);
              if (!$$object_method_defns{$sig}) {
                &generate_object_method_defn($method, $klass_path, &colin($col), $klass_type, __LINE__);
              }
              $$object_method_defns{$sig} = 1;
            }
          }
        }
      } else {
        if (!&is_va($method)) {
          #my $object_method = &convert_to_object_method($method);
          #my $sig = &function::overloadsig($object_method, []);
          #if (!$$object_method_defns{$sig}) {
          #&generate_object_method_decl($method, $klass_path, $col, __LINE__);
          #}
          #$$object_method_defns{$sig} = 1;
        }
      }
    }
    if (0 < keys %$object_method_defns) {
      #print STDERR &Dumper($object_method_defns);
    }
    if (&has_slots($klass_scope)) {
      $$scratch_str_ref .= &generate_klass_unbox($klass_path, $klass_name, $is_klass_defn);
      $$scratch_str_ref .= &generate_klass_box($klass_scope, $klass_path, $klass_name);
    } # if (&has_slots()
    if (&has_exported_slots($klass_scope)) {
      $$scratch_str_ref .= &generate_klass_construct($klass_scope, $klass_name);
    }
  } # if ('klass' eq $klass_type)
  if (&is_decl() && $$klass_scope{'has-initialize'}) {
    $$scratch_str_ref .= $col . "$klass_type $klass_name { object-t initialize(object-t kls); }" . &ann(__FILE__, __LINE__) . "\n";
  }
  if (&is_decl() && $$klass_scope{'has-finalize'}) {
    $$scratch_str_ref .= $col . "$klass_type $klass_name { object-t finalize(object-t kls); }" . &ann(__FILE__, __LINE__) . "\n";
  }
  if (&is_decl() && @$kw_args_methods) {
    #print STDERR Dumper($va_list_methods);
    &generate_kw_args_method_signature_decls($$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_decl() && defined $$klass_scope{'slots-methods'}) {
    #print STDERR Dumper($va_list_methods);
    &generate_slots_method_signature_decls($$klass_scope{'slots-methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_rt() && !&is_decl() && defined $$klass_scope{'slots-methods'}) {
    &generate_slots_method_signature_defns($$klass_scope{'slots-methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_decl() && @$va_list_methods) { #rn0
    #print STDERR Dumper($va_list_methods);
    foreach $method (@$va_list_methods) {
      my $method_decl_ref = &function::decl($method, $klass_path);
      $$scratch_str_ref .= $col . "$klass_type $klass_name { namespace va { VA-METHOD $$method_decl_ref }}" . &ann(__FILE__, __LINE__, "stmt1") . "\n";
    }
  }
  if (@$va_list_methods) {
    foreach $method (@$va_list_methods) {
      if (1) {
        my $va_method = &dakota::util::deep_copy($method);
        #$$va_method{'is-inline'} = 1;
        #if (&is_decl() || &is_same_file($klass_scope)) #rn1
        if (&is_same_src_file($klass_scope) || &is_decl()) { #rn1
          if (defined $$method{'keyword-types'}) {
            &method::generate_va_method_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
            if (0 == @{$$va_method{'keyword-types'}}) {
              my $last = &dakota::util::remove_last($$va_method{'parameter-types'}); # bugbug: should make sure its va-list-t
              my $method_decl_ref = &function::decl($va_method, $klass_path);
              $$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "stmt2") . "\n";
              &dakota::util::add_last($$va_method{'parameter-types'}, $last);
            }
          }
          else {
            &method::generate_va_method_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
          }
        } else {
          &method::generate_va_method_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
        }
        if (&is_decl) {
          if (&is_same_src_file($klass_scope) || &is_rt()) { #rn2
            if (defined $$method{'keyword-types'}) {
              if (0 != @{$$method{'keyword-types'}}) {
                my $other_method_decl = &kw_args_method::type_decl($method);

                #my $scope = &path::string($klass_path);
                $other_method_decl =~ s|\(\*($id)\)| $1|;
                my $visibility = '';
                if (&is_exported($method)) {
                  $visibility = 'SO-EXPORT ';
                }
                if ($$method{'is-inline'}) {
                  #$$scratch_str_ref .= 'INLINE ';
                }
                $$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD " . $visibility . " $other_method_decl; }" . &ann(__FILE__, __LINE__, "stmt3") . "\n";
              }
            }
          }
        }
      }
    }
  }
  #foreach $method (sort method::compare values %{$$klass_scope{'methods'}})
  foreach $method (sort method::compare values %{$$klass_scope{'methods'}}, values %{$$klass_scope{'slots-methods'}}) {
    if (&is_decl) {
      if (&is_same_src_file($klass_scope) || &is_rt()) { #rn3
        if (!&is_va($method)) {
          my $method_decl_ref = &function::decl($method, $klass_path);
          $$scratch_str_ref .= $col . "$klass_type $klass_name { METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "DUPLICATE") . "\n";
        }
      }
    }
  }
}
sub generate_object_method_decl {
  my ($non_object_method, $klass_path, $col, $klass_type, $line) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $object_method = &convert_to_object_method($non_object_method);
  my $method_decl_ref = &function::decl($object_method, $klass_path);
  $$scratch_str_ref .= $col . "$klass_type @$klass_path { METHOD $$method_decl_ref }" . &ann(__FILE__, $line) . "\n";
}
sub generate_object_method_defn {
  my ($non_object_method, $klass_path, $col, $klass_type, $line) = @_;
  my $method = &convert_to_object_method($non_object_method);
  my $new_arg_type = $$method{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'parameter-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  my $new_arg_list  = &arg_type::list_pair($new_arg_type, $new_arg_names);

  my $non_object_return_type = &arg::type($$non_object_method{'return-type'});
  my $return_type = &arg::type($$method{'return-type'});
  my $scratch_str_ref = &global_scratch_str_ref();
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = 'SO-EXPORT ';
  }
  my $method_name = "@{$$method{'name'}}";
  $$scratch_str_ref .= $col . "$klass_type @$klass_path { METHOD " . $visibility . " $return_type $method_name($$new_arg_list)";

  my $new_unboxed_arg_names = &arg_type::names_unboxed($$non_object_method{'parameter-types'});
  my $new_unboxed_arg_names_list = &arg_type::list_names($new_unboxed_arg_names);

  if (&is_nrt_decl() || &is_rt_decl()) {
    $$scratch_str_ref .= ";" . &ann(__FILE__, $line) . " }\n";
  } elsif (&is_rt_defn()) {
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . "\n";
    $col = &colin($col);

    if (defined $$method{'return-type'}) {
      if ($non_object_return_type ne $return_type) {
        $$scratch_str_ref .= $col . "$return_type result = box($method_name($$new_unboxed_arg_names_list));\n";
      } else {
        $$scratch_str_ref .= $col . "$return_type result = $method_name($$new_unboxed_arg_names_list);\n";
      }
    }
    if (defined $$method{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;\n";
    } else {
      $$scratch_str_ref .= $col . "return;\n";
    }
    $col = &colout($col);
    $$scratch_str_ref .= $col . "}}\n";
  }
}
sub convert_to_object_type {
  my ($type_seq) = @_;
  my $result = $type_seq;

  if (&is_box_type($type_seq)) {
    $result = [ 'object-t' ];
  }
  return $result;
}
sub convert_to_object_method {
  my ($non_object_method) = @_;
  my $method = &dakota::util::deep_copy($non_object_method);
  $$method{'return-type'} = &convert_to_object_type($$method{'return-type'});

  foreach my $parameter_type (@{$$method{'parameter-types'}}) {
    $parameter_type = &convert_to_object_type($parameter_type);
  }
  return $method;
}
sub typedef_slots_t {
  my ($klass_name) = @_;
  my $result;
  if ('object' eq $klass_name) {
    $result = "typedef $klass_name\::slots-t* $klass_name-t; /*special-case*/"; # special-case
  } else {
    my $parts = [split(/::/, $klass_name)];
    if (1 < scalar @$parts) {
      my $basename = &remove_last($parts);
      my $ns = join('::', @$parts);
      $result = "namespace $ns { typedef $basename\::slots-t $basename-t; }";
    } else {
      $result = "typedef $klass_name\::slots-t $klass_name-t;";
    }
  }
  return $result;
}
sub generate_slots_decls {
  my ($scope, $col, $klass_path, $klass_name, $klass_scope) = @_;
  if (!$klass_scope) {
    $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  if (!&has_exported_slots($klass_scope) && &has_slots_type($klass_scope)) {
    my $typedef_body = &typedef_body($$klass_scope{'slots'}{'type'}, 'slots-t');
    $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    $$scratch_str_ref .= $col . '//' . &typedef_slots_t($klass_name) . "\n";
  } elsif (!&has_exported_slots($klass_scope) && &has_slots($klass_scope)) {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { ";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
      $$scratch_str_ref .= $col . " }\n";
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $col . '//' . &typedef_slots_t($klass_name) . "\n";
  }
}
sub is_array_type {
  my ($type) = @_;
  my $is_array_type = 0;

  if ($type && $type =~ m|\[.*?\]$|) {
    $is_array_type = 1;
  }
  return $is_array_type;
}
sub typedef_body {
  my ($type, $name) = @_;
  my $is_array_type = &is_array_type($type);
  my $is_function_pointer_type = 0;
  if ($type =~ m|\)\s*\(|) {
    $is_function_pointer_type = 1;
  }
  my $typedef_body = $type;

  if ($is_function_pointer_type && $is_array_type) {
    die __FILE__, ":", __LINE__, ": error:\n";
  } elsif ($is_function_pointer_type) {
    $typedef_body =~ s|\)\s*\(|$name\)\(|g;
  } elsif ($is_array_type) {
    $typedef_body =~ s|\[| $name\[|g;
  } else {
    $typedef_body = "$type $name";
  }
  return $typedef_body
}
sub generate_exported_slots_decls {
  my ($scope, $col, $klass_path, $klass_name, $klass_scope) = @_;
  if (!$klass_scope) {
    $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  if ('object' eq "$klass_name") {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "//klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $col . &typedef_slots_t($klass_name) . &ann(__FILE__, __LINE__) . " // special-case\n";
  } elsif (&has_exported_slots($klass_scope) && &has_slots_type($klass_scope)) {
    my $typedef_body = &typedef_body($$klass_scope{'slots'}{'type'}, 'slots-t');
    $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    my $excluded_types = { 'char16-t' => '__STDC_UTF_16__',
                           'char32-t' => '__STDC_UTF_32__',
                         };
    if (!exists $$excluded_types{"$klass_name-t"}) {
      $$scratch_str_ref .= $col . &typedef_slots_t($klass_name) . "\n";
    }
  } elsif (&has_exported_slots($klass_scope) || (&has_slots($klass_scope) && &is_same_file($klass_scope))) {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . "\n";
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { ";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_scope{'slots'}, $is_exported = 1, $is_slots = 1);
      $$scratch_str_ref .= $col . " }\n";
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $col . &typedef_slots_t($klass_name) . "\n";
  } else {
    #errdump($klass_name);
    #errdump($klass_scope);
    die __FILE__, ':', __LINE__, ": error: box klass \'$klass_name\' without slot or slots\n";
  }
}
sub include_dakota_decl_hh {
  my $result =
    "\n" .
    "#include <dakota-decl.hh>\n" .
    "\n";
  return $result;
}
sub linkage_unit::generate_headers {
  my ($scope, $klass_names) = @_;
  my $result = '';

  if (&is_decl() || &is_rt_defn()) { # not sure if this is right
    my $exported_headers = {};
    $$exported_headers{'<cassert>'}{'hardcoded-by-rnielsen'} = undef; # assert()
    $$exported_headers{'<cstring>'}{'hardcoded-by-rnielsen'} = undef; # memcpy()

    foreach my $klass_name (@$klass_names) {
      my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);

      if (exists $$klass_scope{'exported-headers'} && defined $$klass_scope{'exported-headers'}) {
        while (my ($header, $klasses) = each (%{$$klass_scope{'exported-headers'}})) {
          $$exported_headers{$header} = undef;
        }
      }
    }
    my $all_headers = {};
    my $header_name;
    foreach $header_name (keys %{$$scope{'includes'}}) {
      $$all_headers{$header_name} = undef;
    }
    foreach $header_name (keys %{$$scope{'headers'}}) {
      $$all_headers{$header_name} = undef;
    }
    foreach $header_name (keys %$exported_headers) {
      $$all_headers{$header_name} = undef;
    }
    foreach $header_name (sort keys %$all_headers) {
      $result .= "#include $header_name\n";
    }
  }
  return $result;
}
sub is_same_file {
  my ($klass_scope) = @_;
  my $file = &canon_path($$klass_scope{'slots'}{'file'});
  if ($gbl_nrt_file && $$klass_scope{'slots'} && $$klass_scope{'slots'}{'file'} && ($gbl_nrt_file eq $file)) {
    return 1;
  } else {
    return 0;
  }
}
sub is_same_src_file {
  my ($klass_scope) = @_;
  my $file = &canon_path($$klass_scope{'file'});
  if ($gbl_nrt_file && ($gbl_nrt_file eq $file)) {
    return 1;
  } else {
    return 0;
  }
}
sub has_slots_type {
  my ($klass_scope) = @_;
  if (&has_slots($klass_scope) && exists $$klass_scope{'slots'}{'type'} && $$klass_scope{'slots'}{'type'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_slots_info {
  my ($klass_scope) = @_;
  if (&has_slots($klass_scope) && exists $$klass_scope{'slots'}{'info'} && $$klass_scope{'slots'}{'info'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_enum_info {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'enum'} && $$klass_scope{'enum'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_const_info {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'const'} && $$klass_scope{'const'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_enums {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'enum'} && $$klass_scope{'enum'} && 0 < scalar(@{$$klass_scope{'enum'}})) {
    return 1;
  } else {
    return 0;
  }
}
sub has_slots {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'slots'} && $$klass_scope{'slots'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_exported_slots {
  my ($klass_scope) = @_;
  if (&has_slots($klass_scope) && &is_exported($$klass_scope{'slots'})) {
    return 1;
  } else {
    return 0;
  }
}
sub has_exported_methods {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'behavior-exported?'}  && $$klass_scope{'behavior-exported?'}) {
    return 1;
  } else {
    return 0;
  }
}
sub order_klasses {
  my ($scope) = @_;
  my $type_aliases = {};
  my $depends = {};
  my $verbose = 0;
  my ($klass_name, $klass_scope);

  foreach my $klass_type_plural ('traits', 'klasses') {
    foreach $klass_name (sort keys %{$$scope{$klass_type_plural}}) {
      $klass_scope = $$scope{$klass_type_plural}{$klass_name};
      if (!$klass_scope || !$$klass_scope{'slots'}) {
        # if one has a klass scope locally (like adding a method on klass object)
        # dont use it since it won't have a slots defn
        $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
      }
      if ($klass_scope) {
        if (&has_slots($klass_scope)) {
          # even if not exported
          $$type_aliases{"$klass_name-t"} = "$klass_name\::slots-t";
          # hackhack
          if ($$klass_scope{'slots'}{'info'}) {
            foreach my $slots_info (@{$$klass_scope{'slots'}{'info'}}) {
              my $types = [values %$slots_info];
              foreach my $type (@$types) {
                my $parts = {};
                &klass_part($type_aliases, $type, $parts);
                foreach my $type_klass_name (keys %$parts) {
                  if ($verbose) {
                    print STDERR "    $type\n      $type_klass_name\n";
                  }
                  if (!exists $$scope{'klasses'}{$type_klass_name}) {
                    #$$scope{$klass_type_plural}{$type_klass_name}
                    #  = &generics::klass_scope_from_klass_name($type_klass_name);
                  }
                }
              }
            }
          }
        }
      }
      $$depends{$klass_name} = {};
    }
  }
  if ($verbose) {
    print STDERR &Dumper($type_aliases);
  }
  foreach my $klass_type_plural ('traits', 'klasses') {
    foreach $klass_name (sort keys %{$$scope{$klass_type_plural}}) {
      $klass_scope = $$scope{$klass_type_plural}{$klass_name};
      if (!$klass_scope || !$$klass_scope{'slots'}) {
        # if one has a klass scope locally (like adding a method on klass object)
        # dont use it since it won't have a slots defn
        $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
      }
      if ($klass_scope) {
        if ($verbose) {
          print STDERR "klass-name: $klass_name\n";
        }
        if (&has_slots($klass_scope)) {
          if ($$klass_scope{'slots'}{'type'}) {
            if ($verbose) {
              print STDERR "  type:\n";
            }
            my $type = $$klass_scope{'slots'}{'type'};
            my $type_klass_name;
            my $parts = {};
            &klass_part($type_aliases, $type, $parts);
            foreach $type_klass_name (keys %$parts) {
              if ($verbose) {
                print STDERR "    $type\n      $type_klass_name\n";
              }
              if ($klass_name ne $type_klass_name) {
                $$depends{$klass_name}{$type_klass_name} = 1;
              }
            }
          } elsif ($$klass_scope{'slots'}{'info'}) {
            if ($verbose) {
              print STDERR "  info:\n";
            }
            foreach my $slots_info (@{$$klass_scope{'slots'}{'info'}}) {
              my $types = [values %$slots_info];
              foreach my $type (@$types) {
                my $type_klass_name;
                my $parts = {};
                &klass_part($type_aliases, $type, $parts);
                foreach $type_klass_name (keys %$parts) {
                  if ($verbose) {
                    print STDERR "    $type\n      $type_klass_name\n";
                  }
                  if ($klass_name ne $type_klass_name) {
                    $$depends{$klass_name}{$type_klass_name} = 1;
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  if ($verbose) {
    print STDERR &Dumper($depends);
  }
  my $result = &order_depends($depends);
  if ($verbose) {
    print STDERR &Dumper($$result{'seq'});
  }
  return $$result{'seq'};
} # order_klasses
sub order_depends {
  my ($depends) = @_;
  my $ordered_klasses = { 'seq' => [], 'set' => {} };
  foreach my $klass_name (sort keys %$depends) {
    &order_depends_recursive($depends, $klass_name, $ordered_klasses);
  }
  return $ordered_klasses;
}
sub order_depends_recursive {
  my ($depends, $klass_name, $ordered_klasses) = @_;
  foreach my $lhs (sort keys %{$$depends{$klass_name}}) {
    &order_depends_recursive($depends, $lhs, $ordered_klasses);
  }
  &add_ordered($ordered_klasses, $klass_name);
}
sub add_ordered {
  my ($ordered_klasses, $str) = @_;
  if (!$$ordered_klasses{'set'}{$str}) {
    $$ordered_klasses{'set'}{$str} = 1;
    &add_last($$ordered_klasses{'seq'}, $str);
  } else {
    $$ordered_klasses{'set'}{$str}++;
  }
}
sub klass_part {
  my ($type_aliases, $str, $result) = @_;
  while ($str =~ m/($rid)/g) {
    my $ident = $1;
    if ($ident =~ m/-t$/) {
      my $klass_name = $ident;
      $klass_name =~ s/-t$//;
      if ($klass_name =~ m/^($rid)\::slots$/) {
        $$result{$1} = undef;
      } else {
        if ($$type_aliases{$ident}) {
          &klass_part($type_aliases, $$type_aliases{$ident}, $result);
        }
      }
    }
  }
}
sub linkage_unit::generate_klasses {
  my ($scope, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_types_before($scope, $col, $klass_path, $ordered_klass_names);
  if (&is_decl()) {
    $$scratch_str_ref .=
      "\n" .
      $col . "#include <dakota-finally.$hh_ext> // hackhack: should be before dakota.$hh_ext\n" .
      $col . "#include <dakota.$hh_ext>\n" .
      $col . "#include <dakota-log.$hh_ext>\n";

    if (&is_rt()) {
      $$scratch_str_ref .=
        "\n" .
        $col . "#include <dakota-os.$hh_ext>\n";
    }
    $$scratch_str_ref .= "\n";
  }
  $$scratch_str_ref .= &labeled_src_str(undef, "slots-defns");
  &linkage_unit::generate_klasses_types_after($scope, $col, $klass_path, $ordered_klass_names);

  $$scratch_str_ref .= &labeled_src_str(undef, "klass-defns");
  foreach my $klass_name (sort @$ordered_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass($scope, $col, $klass_path, $klass_name);
  }
  return $$scratch_str_ref;
}
sub linkage_unit::generate_klasses_types_before {
  my ($scope, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  $$scratch_str_ref .= &labeled_src_str(undef, "klass-decls");
  if (&is_decl()) {
    foreach my $klass_name (@$ordered_klass_names) { # do not sort!
      my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);

      if (&has_exported_slots($klass_scope) || (&has_slots($klass_scope) && &is_same_file($klass_scope))) {
        &generate_exported_slots_decls($scope, $col, $klass_path, $klass_name, $klass_scope);
      } else {
        &generate_slots_decls($scope, $col, $klass_path, $klass_name, $klass_scope);
      }
    }
  }
}
sub linkage_unit::generate_klasses_types_after {
  my ($scope, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  foreach my $klass_name (@$ordered_klass_names) { # do not sort!
    my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
    my $is_exported;
    my $is_slots;

    if (&is_decl()) {
      if (&has_enums($klass_scope)) {
        foreach my $enum (@{$$klass_scope{'enum'} ||= []}) {
          if (&is_exported($enum)) {
            $$scratch_str_ref .= $col . "klass $klass_name { ";
            &generate_enum_defn(&colin($col), $enum, $is_exported = 1, $is_slots = 0);
            $$scratch_str_ref .= $col . " }\n";
          }
        }
      }
    }
    if (&has_slots_info($klass_scope)) {
      if (&is_decl()) {
        if (&has_exported_slots($klass_scope) || (&has_slots($klass_scope) && &is_same_file($klass_scope))) {
          $$scratch_str_ref .= $col . "klass $klass_name {";
          if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
              'union'  eq $$klass_scope{'slots'}{'cat'}) {
            &generate_struct_or_union_defn(&colin($col), $$klass_scope{'slots'}, $is_exported = 1, $is_slots = 1);
          } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
            &generate_enum_defn(&colin($col), $$klass_scope{'slots'}, $is_exported = 1, $is_slots = 1);
          } else {
            print STDERR &Dumper($$klass_scope{'slots'});
            die __FILE__, ":", __LINE__, ": error:\n";
          }
          $$scratch_str_ref .= $col . " }\n";
        }
      } elsif (&is_nrt_defn() || &is_rt_defn()) {
        if (!&has_exported_slots($klass_scope)) {
          if (&is_exported($klass_scope)) {
            $$scratch_str_ref .= $col . "klass $klass_name {";
            if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
                'union'  eq $$klass_scope{'slots'}{'cat'}) {
              &generate_struct_or_union_defn(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
            } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
              &generate_enum_defn(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
            } else {
              print STDERR &Dumper($$klass_scope{'slots'});
              die __FILE__, ":", __LINE__, ": error:\n";
            }
            $$scratch_str_ref .= $col . " }\n";
          } else {
            $$scratch_str_ref .= $col . "klass $klass_name {";
            if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
                'union'  eq $$klass_scope{'slots'}{'cat'}) {
              &generate_struct_or_union_defn(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
            } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
              &generate_enum_decl(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
            } else {
              print STDERR &Dumper($$klass_scope{'slots'});
              die __FILE__, ":", __LINE__, ": error:\n";
            }
            $$scratch_str_ref .= $col . " }\n";
          }
        }
      }
    }
  }
  $$scratch_str_ref .= "\n";
}
sub linkage_unit::generate_klasses_klass {
  my ($scope, $col, $klass_path, $klass_name) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  if (&is_exported($klass_scope) || &has_exported_slots($klass_scope) || &has_exported_methods($klass_scope)) {
    &linkage_unit::generate_klasses_body($klass_scope, $col, $klass_type, $klass_path, $klass_name);
  } else {
    #} elsif (!&has_exported_slots($klass_scope) && !&is_exported($klass_scope)) {
    &linkage_unit::generate_klasses_body($klass_scope, $col, $klass_type, $klass_path, $klass_name);
  }
  &path::remove_last($klass_path);
}
sub method::type {
  my ($method, $return_type) = @_;
  my $return_type_str;
  if (!$return_type) {
    $return_type_str = &arg::type($$method{'return-type'});
  } else {
    $return_type_str = &arg::type($return_type);
  }
  my $arg_type_list = &arg_type::list_types($$method{'parameter-types'});
  return "$return_type_str(*)($$arg_type_list)";
}
sub method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &arg_type::list_types($$method{'parameter-types'});
  my $name = &dakota::util::last($$method{'name'});
  return "$return_type(*$name)($$arg_type_list)";
}
sub kw_args_method::type {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'parameter-types'}, $$method{'keyword-types'});
  return "$return_type(*)($$arg_type_list)";
}
sub kw_args_method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'parameter-types'}, $$method{'keyword-types'});
  my $name = &dakota::util::last($$method{'name'});
  return "$return_type(*$name)($$arg_type_list)";
}
sub slots_signature_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num  = 0;
  my $max_width = 0;
  my $return_type = 'signature-t const*';
  foreach my $method (@$sorted_methods) {
    my $method_type = &method::type($method, [ $return_type ]);
    my $width = length($method_type);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $method (@$sorted_methods) {
    my $method_type = &method::type($method, [ $return_type ]);
    my $width = length($method_type);
    my $pad = ' ' x ($max_width - $width);

    if (!$$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = "@{$$method{'name'}}";
      if (&is_va($method)) {
        $result .= $col . "(cast(dkt-signature-function-t)cast($method_type)" . $pad . "__slots-signature::va::$generic_name)(),\n";
      } else {
        $result .= $col . "(cast(dkt-signature-function-t)cast($method_type)" . $pad . "__slots-signature::$generic_name)(),\n";
      }
      my $method_name;

      if ($$method{'alias'}) {
        $method_name = "@{$$method{'alias'}}";
      } else {
        $method_name = "@{$$method{'name'}}";
      }
    }
    $method_num++;
  }
  $result .= $col . "nullptr\n";
  return $result;
}
sub signature_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num  = 0;
  my $max_width = 0;
  my $return_type = 'signature-t const*';
  foreach my $method (@$sorted_methods) {
    my $method_type = &method::type($method, [ $return_type ]);
    my $width = length($method_type);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $method (@$sorted_methods) {
    my $method_type = &method::type($method, [ $return_type ]);
    my $width = length($method_type);
    my $pad = ' ' x ($max_width - $width);

    if (!$$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = "@{$$method{'name'}}";
      my $in = &ident_comment($generic_name);
      if (&is_va($method)) {
        $result .= $col . "(cast(dkt-signature-function-t)cast($method_type)" . $pad . "__signature::va::$generic_name)()," . $in . "\n";
      } else {
        $result .= $col . "(cast(dkt-signature-function-t)cast($method_type)" . $pad . "__signature::$generic_name)()," . $in . "\n";
      }
      my $method_name;

      if ($$method{'alias'}) {
        $method_name = "@{$$method{'alias'}}";
      } else {
        $method_name = "@{$$method{'name'}}";
      }
    }
    $method_num++;
  }
  $result .= $col . "nullptr\n";
  return $result;
}
sub address_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num  = 0;
  my $max_width = 0;
  foreach my $method (@$sorted_methods) {
    if (!$$method{'defined?'} && !$$method{'alias'} && !$$method{'is-generated'}) {
      # skip because its declared but not defined and should not be considered for padding
    } else {
      my $method_type = &method::type($method);
      my $width = length("cast($method_type)");
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
  }
  foreach my $method (@$sorted_methods) {
    my $method_type = &method::type($method);
    my $width = length("cast($method_type)");
    my $pad = ' ' x ($max_width - $width);

    if (!$$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = "@{$$method{'name'}}";
      my $method_name;

      if ($$method{'alias'}) {
        $method_name = "@{$$method{'alias'}}";
      } else {
        $method_name = "@{$$method{'name'}}";
      }
      my $in = &ident_comment($method_name);

      if (!$$method{'defined?'} && !$$method{'alias'} && !$$method{'is-generated'}) {
        $pad = ' ' x $max_width;
        $result .=   $col . "cast(method-t)"                   . $pad . "dkt-null-method, /*$method_name()*/\n";
      } else {
        if (&is_va($method)) {
          $result .= $col . "cast(method-t)cast($method_type)" . $pad . "va::$method_name," . $in . "\n";
        } else {
          $result .= $col . "cast(method-t)cast($method_type)" . $pad . "$method_name," . $in . "\n";
        }
      }
    }
    $method_num++;
  }
  $result .= $col . "nullptr\n";
  return $result;
}
sub alias_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num  = 0;
  foreach my $method (@$sorted_methods) {
    if ($$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = "@{$$method{'name'}}";
      my $alias_name = "@{$$method{'alias'}}";
      if (&is_va($method)) {
        $result .= $col . "{ dkt-signature(va::$alias_name($$new_arg_type_list)), dkt-signature(va::$generic_name($$new_arg_type_list)) },\n";
      } else {
        $result .= $col . "{ dkt-signature($alias_name($$new_arg_type_list)), dkt-signature($generic_name($$new_arg_type_list)) },\n";
      }
    }
    $method_num++;
  }
  $result .= $col . "{ nullptr, nullptr }\n";
  return $result;
}
sub export_pair {
  my ($symbol, $element) = @_;
  my $name = "@{$$element{'name'}}";
  my $type0 = "@{$$element{'parameter-types'}[0]}";
  $type0 = '';                  # hackhack
  my $lhs = "\"$symbol::$name($type0)\"";
  my $rhs = 1;
  return ($lhs, $rhs);
}
sub exported_methods {
  my ($klass_scope) = @_;
  my $exported_methods = {};
  {
    while (my ($key, $val) = each (%{$$klass_scope{'methods'}})) {
      if (&is_exported($val)) {
        $$exported_methods{$key} = $val;
      }
    }
  }
  return $exported_methods;
}
sub exported_slots_methods {
  my ($klass_scope) = @_;
  my $exported_slots_methods = {};
  {
    while (my ($key, $val) = each (%{$$klass_scope{'slots-methods'}})) {
      if (&is_exported($val)) {
        $$exported_slots_methods{$key} = $val;
      }
    }
  }
  return $exported_slots_methods;
}
sub exports {
  my ($scope) = @_;
  my $exports = {};

  foreach my $klass_type ('klass', 'trait') {
    while (my ($klass_name, $klass_scope) = each(%{$$scope{$$plural_from_singular{$klass_type}}})) {
      my $exported_methods = &exported_methods($klass_scope);
      my $exported_slots_methods = &exported_slots_methods($klass_scope);

      while (my ($key, $element) = each (%$exported_methods)) {
        my ($lhs, $rhs) = &export_pair($klass_name, $element);
        $$exports{"\#$$klass_scope{'module'}"}{$lhs} = $rhs;
      }
      while (my ($key, $element) = each (%$exported_slots_methods)) {
        my ($lhs, $rhs) = &export_pair($klass_name, $element);
        $$exports{"\#$$klass_scope{'module'}"}{$lhs} = $rhs;
      }

      if (&is_exported($klass_scope)) {
        my $lhs = "\#$klass_name";
        my $rhs = 1;
        $$exports{"\#$$klass_scope{'module'}"}{$lhs} = $rhs;
      }

      if (&has_exported_slots($klass_scope)) {
        my $lhs = "\#$klass_name\::slots-t";
        my $rhs = 1;
        $$exports{"\#$$klass_scope{'module'}"}{$lhs} = $rhs;
      }
    }
  }
  return $exports;
}
sub dk_generate_cc_footer_klass {
  my ($klass_scope, $klass_name, $col, $klass_type, $symbols) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_cc_footer_klass()\n";

  my $token_registry = {};

  my $slot_type;
  my $slot_name;

  my $method_aliases = &klass::method_aliases($klass_scope);
  my $va_list_methods = &klass::va_list_methods($klass_scope);
  my $kw_args_methods = &klass::kw_args_methods($klass_scope);

  my $va_method_num = 0;
  #my $num_va_methods = @$va_list_methods;

  #if (@$va_list_methods)
  #{
  #$$scratch_str_ref .= $col . "namespace va {\n";
  #$col = &colin($col);
  ###
  if (@$va_list_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static signature-t const* const __va-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " // redundant\n";

    my $sorted_va_methods = [sort method::compare @$va_list_methods];

    $va_method_num = 0;
    my $max_width = 0;
    my $return_type = 'signature-t const*';
    foreach my $va_method (@$sorted_va_methods) {
      my $va_method_type = &method::type($va_method, [ $return_type ]);
      my $width = length($va_method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    $col = &colin($col);
    foreach my $va_method (@$sorted_va_methods) {
      my $va_method_type = &method::type($va_method, [ $return_type ]);
      my $width = length($va_method_type);
      my $pad = ' ' x ($max_width - $width);

      if ($$va_method{'defined?'} || $$va_method{'alias'}) {
        my $new_arg_names_list = &arg_type::list_types($$va_method{'parameter-types'});

        my $generic_name = "@{$$va_method{'name'}}";

        $$scratch_str_ref .= $col . "(cast(dkt-signature-function-t)cast($va_method_type)" . $pad . "__signature::va::$generic_name)(),\n";
        my $method_name;

        if ($$va_method{'alias'}) {
          $method_name = "@{$$va_method{'alias'}}";
        } else {
          $method_name = "@{$$va_method{'name'}}";
        }

        my $old_parameter_types = $$va_method{'parameter-types'};
        $$va_method{'parameter-types'} = &arg_type::va($$va_method{'parameter-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'parameter-types'} = $old_parameter_types;

        my $return_type = &arg::type($$va_method{'return-type'});
        my $va_method_name = $method_name;
        #$$scratch_str_ref .= $col . "(va-method-t)(($method_type)$va_method_name),\n";
      }
      $va_method_num++;
    }
    $$scratch_str_ref .= $col . "nullptr,\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  ###
  ###
  if (@$va_list_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static va-method-t __va-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    ### todo: this looks like it might merge with address_body(). see die below
    my $sorted_va_methods = [sort method::compare @$va_list_methods];

    $va_method_num = 0;
    my $max_width = 0;
    foreach my $va_method (@$sorted_va_methods) {
      $va_method = &dakota::util::deep_copy($va_method);
      my $va_method_type = &method::type($va_method);
      my $width = length($va_method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    foreach my $va_method (@$sorted_va_methods) {
      $va_method = &dakota::util::deep_copy($va_method);
      my $va_method_type = &method::type($va_method);
      my $width = length($va_method_type);
      my $pad = ' ' x ($max_width - $width);

      if ($$va_method{'defined?'} || $$va_method{'alias'}) {
        my $new_arg_names_list = &arg_type::list_types($$va_method{'parameter-types'});

        my $generic_name = "@{$$va_method{'name'}}";
        my $method_name;

        if ($$va_method{'alias'}) {
          $method_name = "@{$$va_method{'alias'}}";
        } else {
          $method_name = "@{$$va_method{'name'}}";
        }
        die if (!$$va_method{'defined?'} && !$$va_method{'alias'} && !$$va_method{'is-generated'});

        my $old_parameter_types = $$va_method{'parameter-types'};
        $$va_method{'parameter-types'} = &arg_type::va($$va_method{'parameter-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'parameter-types'} = $old_parameter_types;

        my $return_type = &arg::type($$va_method{'return-type'});
        my $va_method_name = $method_name;
        $$scratch_str_ref .= $col . "cast(va-method-t)cast($method_type)" . $pad . "$va_method_name,\n";
      }
      $va_method_num++;
    }
    $$scratch_str_ref .= $col . "nullptr,\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  ###
  #$col = &colout($col);
  #$$scratch_str_ref .= $col . "}\n";
  #}
  ###
  if (@$kw_args_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static signature-t const* const __kw-args-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    #$col = &colin($col);

    #$$scratch_str_ref .= "\#if 0\n";
    my $max_width = 0;
    foreach my $kw_args_method (@$kw_args_methods) {
      $kw_args_method = &dakota::util::deep_copy($kw_args_method);
      my $kw_args_method_type = &kw_args_method::type($kw_args_method);
      my $width = length($kw_args_method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    foreach my $kw_args_method (@$kw_args_methods) {
      $kw_args_method = &dakota::util::deep_copy($kw_args_method);
      my $kw_args_method_type = &kw_args_method::type($kw_args_method);
      my $width = length($kw_args_method_type);
      my $pad = ' ' x ($max_width - $width);

      my $method_name = "@{$$kw_args_method{'name'}}";
      my $list_types = &arg_type::list_types($$kw_args_method{'parameter-types'});
      my $kw_list_types = &method::kw_list_types($kw_args_method);
      $$scratch_str_ref .=
        $col . "  (cast(dkt-signature-function-t)cast(signature-t const*(*)($$list_types))" .
        $pad . "__kw-args-signature::va::$method_name)(),\n";
    }
    #$$scratch_str_ref .= "\#endif\n";
    $$scratch_str_ref .= $col . "  nullptr\n";
    $$scratch_str_ref .= $col . "};}\n";
  }
  if (values %{$$klass_scope{'methods'} ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static signature-t const* const __method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &signature_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}\n";
  }
  if (values %{$$klass_scope{'methods'} ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-t __method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &address_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}\n";
  }
  my $num_method_aliases = scalar(@$method_aliases);
  if ($num_method_aliases) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-alias-t __method-aliases[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &alias_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}\n";
  }
  my $exported_methods =     &exported_methods($klass_scope);
  my $exported_slots_methods = &exported_slots_methods($klass_scope);

  if (values %{$exported_methods ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static signature-t const* const __exported-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &signature_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}\n" .
      $col . "$klass_type @$klass_name { static method-t __exported-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &address_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}\n";
  }
  if (values %{$exported_slots_methods ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static signature-t const* const __exported-slots-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &slots_signature_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}\n" .
      $col . "$klass_type @$klass_name { static method-t __exported-slots-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n" .
      $col . &address_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}\n";
  }
  ###
  ###
  ###
  #$$scratch_str_ref .= "\n";

  my $num_traits = @{( $$klass_scope{'traits'} ||= [] )}; # how to get around 'strict'
  if ($num_traits > 0) {
    $$scratch_str_ref .= "\n";
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __traits[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    my $trait_num = 0;
    for ($trait_num = 0; $trait_num < $num_traits; $trait_num++) {
      my $path = "$$klass_scope{'traits'}[$trait_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__,\n";
    }
    $$scratch_str_ref .= $col . "nullptr\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  my $num_requires = @{( $$klass_scope{'requires'} ||= [] )}; # how to get around 'strict'
  if ($num_requires > 0) {
    $$scratch_str_ref .= "\n";
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __requires[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    my $require_num = 0;
    for ($require_num = 0; $require_num < $num_requires; $require_num++) {
      my $path = "$$klass_scope{'requires'}[$require_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__,\n";
    }
    $$scratch_str_ref .= $col . "nullptr\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  my $num_provides = @{( $$klass_scope{'provides'} ||= [] )}; # how to get around 'strict'
  if ($num_provides > 0) {
    $$scratch_str_ref .= "\n";
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __provides[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    my $provide_num = 0;
    for ($provide_num = 0; $provide_num < $num_provides; $provide_num++) {
      my $path = "$$klass_scope{'provides'}[$provide_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__,\n";
    }
    $$scratch_str_ref .= $col . "nullptr\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  while (my ($key, $val) = each(%{$$klass_scope{'imported-klasses'}})) {
    my $token;
    my $token_seq = $key;
    if (0 != length $token_seq) {
      my $path = $key;

      if (!$$token_registry{$path}) {
        $$token_registry{$path} = 1;
      }
    }
  }
  my $num_bound = keys %{$$klass_scope{'imported-klasses'}};
  if ($num_bound) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t const __imported-klasses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    while (my ($key, $val) = each(%{$$klass_scope{'imported-klasses'}})) {
      $$scratch_str_ref .= $col . "$key\::__klass__,\n";
    }
    $$scratch_str_ref .= $col . "nullptr\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  my $lines = [];
  my $tbbl = {};
  my $token;
  my $token_seq;
  $token_seq = $klass_name;
  if (0 != @$token_seq) {
    my $path = $klass_name;

    if (!$$token_registry{$path}) {
      $$token_registry{$path} = 1;

      foreach $token (@$klass_name) {
        #               $$scratch_str_ref .= $col . "\"$gbl_token\", ";
      }
      #           $$scratch_str_ref .= "  nullptr }; ";
    }
  }
  if (&has_slots_info($klass_scope)) {
    my $root_name = '__slots-info';
    if ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      my $seq = [];
      my $prop_num = 0;
      foreach my $slot_info (@{$$klass_scope{'slots'}{'info'}}) {
        my $tbl = {};
        $$tbl{'#name'} = "\#$$slot_info{'name'}";
        if (defined $$slot_info{'expr'}) {
          $$tbl{'#expr'} = "\"$$slot_info{'expr'}\"";
          $$tbl{'#expr-str'} = "\"$$slot_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }\n";
        &dakota::util::add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_info_seq($root_name, $seq, $col, __LINE__) . "}\n";
    } else {
      my $seq = [];
      my $prop_num = 0;
      foreach my $slot_info (@{$$klass_scope{'slots'}{'info'}}) {
        my $tbl = {};
        $$tbl{'#name'} = "\#$$slot_info{'name'}";

        if ('struct' eq $$klass_scope{'slots'}{'cat'}) {
          $$tbl{'#offset'} = "offsetof(slots-t, $$slot_info{'name'})";
        }
        $$tbl{'#size'} = "sizeof((cast(slots-t*)nullptr)->$$slot_info{'name'})";
        $$tbl{'#type'} = "\"$$slot_info{'type'}\"";

        if ($$slot_info{'expr'}) {
          $$tbl{'#expr'} = "($$slot_info{'expr'})";
          $$tbl{'#expr-str'} = "\"$$slot_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }\n";
        &dakota::util::add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_info_seq($root_name, $seq, $col, __LINE__) . " }\n";
    }
  }
  if (&has_enum_info($klass_scope)) {
    my $num = 0;
    foreach my $enum (@{$$klass_scope{'enum'}}) {
      $$scratch_str_ref .= $col . "$klass_type @$klass_name { static enum-info-t __enum-info-$num\[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
      $col = &colin($col);

      my $slots_info = $$enum{'info'};
      foreach my $slot_info (@$slots_info) {
        my $name = $$slot_info{'name'};
        if ($$slots_info{'expr'}) {
          my $expr = $$slot_info{'expr'};
          $$scratch_str_ref .= $col . "{ \#$name, $expr },\n";
        } else {
          $$scratch_str_ref .= $col . "{ \#$name, nullptr },\n";
        }
      }
      $$scratch_str_ref .= $col . "{ nullptr, nullptr }\n";
      $col = &colout($col);
      $$scratch_str_ref .= $col . "};}\n";

      $num++;
    }
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static named-enum-info-t __enum-info[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);
    $num = 0;
    foreach my $enum (@{$$klass_scope{'enum'}}) {
      if ($$enum{'type'}) {
        my $type = "@{$$enum{'type'}}";
        $$scratch_str_ref .= $col . "{ \"$type\", __enum-info-$num },\n";
      } else {
        $$scratch_str_ref .= $col . "{ nullptr, __enum-info-$num },\n";
      }
      $num++;
    }
    $$scratch_str_ref .= $col . "{ nullptr, nullptr }\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  if (&has_const_info($klass_scope)) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const-info-t __const-info\[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
    $col = &colin($col);

    foreach my $const (@{$$klass_scope{'const'}}) {
      my $delim = $";
      $" = ' ';
      my $value = "@{$$const{'rhs'}}";
      $" = $delim;
      $value =~ s/"/\\"/g;
      $$scratch_str_ref .= $col . "{ \#$$const{'name'}, \"$$const{'type'}\", \"$value\" },\n";
    }
    $$scratch_str_ref .= $col . "{ nullptr, nullptr, nullptr }\n";
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}\n";
  }
  my $symbol = &path::string($klass_name);
  $$tbbl{'#name'} = '__klass__';
  $$tbbl{'#construct'} = "\#$klass_type";

  if (&has_slots_type($klass_scope)) {
    my $slots_type_ident = &make_ident_symbol_scalar($$klass_scope{'slots'}{'type'});
    my $type_symbol = $$klass_scope{'slots'}{'type'};
    $$tbbl{'#slots-type'} = "\"$type_symbol\"";
  } elsif (&has_slots_info($klass_scope)) {
    my $cat = $$klass_scope{'slots'}{'cat'};
    $$tbbl{'#cat'} = "\#$cat";
    $$tbbl{'#slots-info'} = '__slots-info';
  }
  if ($$klass_scope{'slots'}{'enum-base'}) {
    $$tbbl{'#enum-base'} = "\"$$klass_scope{'slots'}{'enum-base'}\"";
  }
  if (&has_slots_type($klass_scope) || &has_slots_info($klass_scope)) {
    $$tbbl{'#size'} = 'sizeof(slots-t)';
  }
  if (&has_enum_info($klass_scope)) {
    $$tbbl{'#enum-info'} = '__enum-info';
  }
  if (&has_const_info($klass_scope)) {
    $$tbbl{'#const-info'} = '__const-info';
  }
  if (@$kw_args_methods) {
    $$tbbl{'#kw-args-method-signatures'} = '__kw-args-method-signatures';
  }
  if (values %{$$klass_scope{'methods'}}) {
    $$tbbl{'#method-signatures'} = '__method-signatures';
    $$tbbl{'#method-addresses'}  = '__method-addresses';
  }
  if ($num_method_aliases) {
    $$tbbl{'#method-aliases'} = '&__method-aliases';
  }
  if (values %{$exported_methods ||= []}) {
    $$tbbl{'#exported-method-signatures'} = '__exported-method-signatures';
    $$tbbl{'#exported-method-addresses'}  = '__exported-method-addresses';
  }
  if (values %{$exported_slots_methods ||= []}) {
    $$tbbl{'#exported-slots-method-signatures'} = '__exported-slots-method-signatures';
    $$tbbl{'#exported-slots-method-addresses'}  = '__exported-slots-method-addresses';
  }
  if (@$va_list_methods) {
    $$tbbl{'#va-method-signatures'} = '__va-method-signatures';
    $$tbbl{'#va-method-addresses'}  = '__va-method-addresses';
  }
  $token_seq = $$klass_scope{'interpose'};
  if ($token_seq) {
    my $path = $$klass_scope{'interpose'};
    $$tbbl{'#interpose-name'} = "$path\::__klass__";
  }
  $token_seq = $$klass_scope{'superklass'};
  if ($token_seq) {
    my $path = $$klass_scope{'superklass'};
    $$tbbl{'#superklass-name'} = "$path\::__klass__";
  }
  $token_seq = $$klass_scope{'klass'};
  if ($token_seq) {
    my $path = $$klass_scope{'klass'};
    $$tbbl{'#klass-name'} = "$path\::__klass__";
  }
  if ($num_traits > 0) {
    $$tbbl{'#traits'} = '__traits';
  }
  if ($num_requires > 0) {
    $$tbbl{'#requires'} = '__requires';
  }
  if ($num_provides > 0) {
    $$tbbl{'#provides'} = '__provides';
  }
  if (&is_exported($klass_scope)) {
    $$tbbl{'#exported?'} = '1';
  }
  if (&has_exported_slots($klass_scope)) {
    $$tbbl{'#state-exported?'} = '1';
  }
  if (&has_exported_methods($klass_scope)) {
    $$tbbl{'#behavior-exported?'} = '1';
  }
  if ($$klass_scope{'has-initialize'}) {
    $$tbbl{'#initialize'} = 'cast(method-t)initialize';
  }
  if ($$klass_scope{'has-finalize'}) {
    $$tbbl{'#finalize'} = 'cast(method-t)finalize';
  }
  if ($$klass_scope{'module'}) {
    $$tbbl{'#module'} = "\#$$klass_scope{'module'}";
  }
  $$tbbl{'#file'} = '__FILE__';
  $$scratch_str_ref .=
    $col . "$klass_type @$klass_name { " . &generate_property_tbl('__klass-props', $tbbl, $col, $symbols, __LINE__) .
    $col . " }\n";
  &dakota::util::add_last($global_klass_defns, "$symbol\::__klass-props");
  return $$scratch_str_ref;
}
sub generate_kw_args_method_signature_decls {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if ($$method{'keyword-types'}) {
      &generate_kw_args_method_signature_decl($method, $klass_name, $col, $klass_type);
    }
  }
}
sub generate_kw_args_method_signature_defns {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if ($$method{'keyword-types'}) {
      &generate_kw_args_method_signature_defn($method, $klass_name, $col, $klass_type);
    }
  }
}
sub generate_slots_method_signature_decls {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    &generate_slots_method_signature_decl($method, $klass_name, $col, $klass_type);
  }
}
sub generate_slots_method_signature_defns {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    &generate_slots_method_signature_defn($method, $klass_name, $col, $klass_type);
  }
}
sub generate_kw_args_method_signature_decl {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $return_type = &arg::type($$method{'return-type'});
  my $method_name = "@{$$method{'name'}}";
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  my $kw_list_types = &method::kw_list_types($method);
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __kw-args-signature { namespace va { KW-ARGS-METHOD-SIGNATURE signature-t const* $method_name($$list_types); }}}" . &ann(__FILE__, __LINE__) . "\n";
}
sub generate_kw_args_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = "@{$$method{'name'}}";
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __kw-args-signature { namespace va { KW-ARGS-METHOD-SIGNATURE signature-t const* $method_name($$list_types) {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);

  my $kw_arg_list = "static signature-t const result = { \"$return_type\", \"$method_name\", \"";
  $kw_arg_list .= &method::kw_list_types($method);
  $kw_arg_list .= "\" };";
  $$scratch_str_ref .=
    $col . "$kw_arg_list\n" .
    $col . "return &result;\n";
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}}\n";
}
sub generate_slots_method_signature_decl {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = "@{$$method{'name'}}";
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __slots-signature { SLOTS-SIGNATURE signature-t const* $method_name($$list_types); }}" . &ann(__FILE__, __LINE__) . "\n";
}
sub generate_slots_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = "@{$$method{'name'}}";
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __slots-signature { SLOTS-SIGNATURE signature-t const* $method_name($$list_types) {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);

  my $arg_list = "static signature-t const result = { \"$return_type\", \"$method_name\", \"";
  $arg_list .= &method::list_types($method);
  $arg_list .= "\" };";
  $$scratch_str_ref .=
    $col . "$arg_list\n" .
    $col . "return &result;\n";
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}\n";
}
sub generate_kw_args_method_defns {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if ($$method{'keyword-types'}) {
      &generate_kw_args_method_defn($method, $klass_name, $col, $klass_type);
    }
  }
}
sub generate_kw_args_method_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_kw_args_method_defn()\n";

  my $qualified_klass_name = &path::string($klass_name);

  #    &path::add_last($klass_name, 'va');
  my $new_arg_type = $$method{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'parameter-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  &dakota::util::_replace_first($new_arg_names, 'self');
  &dakota::util::_replace_last($new_arg_names, '_args_');
  my $new_arg_list  = &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$method{'return-type'});
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = 'SO-EXPORT ';
  }
  my $func_spec = '';
  #if ($$method{'is-inline'})
  #{
  #    $func_spec = 'INLINE ';
  #}
  my $method_name = "@{$$method{'name'}}";
  my $method_type_decl;
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  my $list_names = &arg_type::list_names($$method{'parameter-types'});

  $$scratch_str_ref .=
    "$klass_type @$klass_name { namespace va { KW-ARGS-METHOD " . $visibility . $func_spec . "$return_type $method_name($$new_arg_list) {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);

  $$scratch_str_ref .=
    $col . "static signature-t const* __method__ = dkt-kw-args-signature(va::$method_name($$list_types)); USE(__method__);\n";

  $$method{'name'} = [ '_func_' ];
  my $func_name = "@{$$method{'name'}}";

  #$$scratch_str_ref .=
  #  $col . "static signature-t const* __method__ = dkt-kw-args-signature(va::$method_name($$list_types)); USE(__method__);\n";

  my $arg_names = &dakota::util::deep_copy(&arg_type::names(&dakota::util::deep_copy($$method{'parameter-types'})));
  my $arg_names_list = &arg_type::list_names($arg_names);

  if (0 < @{$$method{'keyword-types'}}) {
    #my $param = &dakota::util::remove_last($$method{'parameter-types'}); # remove uintptr-t type
    $method_type_decl = &kw_args_method::type_decl($method);
    #&dakota::util::add_last($$method{'parameter-types'}, $param);
  } else {
    my $param1 = &dakota::util::remove_last($$method{'parameter-types'}); # remove va-list-t type
    # should test $param1
    #my $param2 = &dakota::util::remove_last($$method{'parameter-types'}); # remove uintptr-t type
    ## should test $param2
    $method_type_decl = &method::type_decl($method);
    #&dakota::util::add_last($$method{'parameter-types'}, $param2);
    &dakota::util::add_last($$method{'parameter-types'}, $param1);
  }
  if (scalar @{$$method{'keyword-types'}}) {
    $$scratch_str_ref .= $col;
    my $delim = '';
    foreach my $kw_arg (@{$$method{'keyword-types'}}) {
      my $kw_arg_name = $$kw_arg{'name'};
      my $kw_arg_type = &arg::type($$kw_arg{'type'});
      $$scratch_str_ref .= "$delim$kw_arg_type $kw_arg_name \{};";
      $delim = ' ';
    }
    $$scratch_str_ref .= "\n";
    $$scratch_str_ref .= $col . "struct {";
    my $initializer = '';
    $delim = '';
    foreach my $kw_arg (@{$$method{'keyword-types'}}) {
      my $kw_arg_name = $$kw_arg{'name'};
      $$scratch_str_ref .= " boole-t $kw_arg_name;";
      $initializer .= "${delim}false";
      $delim = ', ';
    }
    $$scratch_str_ref .= " } _state_ = { $initializer };\n";
  }
  #$$scratch_str_ref .= $col . "if (NULLPTR != $$new_arg_names[-1]) {\n";
  #$col = &colin($col);
  $$scratch_str_ref .=
    $col . "keyword-t* _keyword_;\n" .
    $col . "while (NULLPTR != (_keyword_ = va-arg(_args_, decltype(_keyword_)))) {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  $$scratch_str_ref .= $col . "switch (_keyword_->hash) { // hash is a constexpr. its compile-time evaluated.\n";
  $col = &colin($col);
  my $kw_arg_name;

  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    $kw_arg_name = $$kw_arg{'name'};
    $$scratch_str_ref .= $col . "case dk-hash(\"$kw_arg_name\"): // dk-hash() is a constexpr. its compile-time evaluated.\n";
    #            $$scratch_str_ref .= $col . "{\n";
    $col = &colin($col);
    my $kw_type = &arg::type($$kw_arg{'type'});

    if ('boole-t' eq $kw_type) {
      $kw_type = 'dkt-va-arg-boole-t'; # bools are promoted to ints
    }
    # should do this for other types (char=>int, float=>double, ... ???
    $$scratch_str_ref .=
      $col . "assert(_keyword_->symbol == \#$kw_arg_name);\n" .
      $col . "$kw_arg_name = va-arg($$new_arg_names[-1], decltype($kw_arg_name));\n" .
      $col . "_state_.$kw_arg_name = true;\n" .
      $col . "break;\n";
    $col = &colout($col);
    #            $$scratch_str_ref .= $col . "}\n";
  }
  $$scratch_str_ref .= $col . "default:\n";
  #        $$scratch_str_ref .= $col . "{\n";
  $col = &colin($col);
  $$scratch_str_ref .=
    $col . "throw make(no-such-keyword-exception::klass,\n" .
    $col . "           \#object $colon    self,\n" .
    $col . "           \#signature $colon __method__,\n" .
    $col . "           \#keyword $colon   _keyword_->symbol);\n";
  $col = &colout($col);
  #        $$scratch_str_ref .= $col . "}\n";
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}\n";
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}\n";

  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name    = $$kw_arg{'name'};
    $$scratch_str_ref .= $col . "unless (_state_.$kw_arg_name)\n";
    $col = &colin($col);
    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default = $$kw_arg{'default'};
      $$scratch_str_ref .= $col . "$kw_arg_name = $kw_arg_default;\n";
    } else {
      $$scratch_str_ref .=
        $col . "throw make(missing-keyword-exception::klass,\n" .
        $col . "           \#object $colon    self,\n" .
        $col . "           \#signature $colon __method__,\n" .
        $col . "           \#keyword $colon   _keyword_->symbol);\n";
    }
    $col = &colout($col);
  }
  my $delim = '';
  #my $last_arg_name = &dakota::util::remove_last($new_arg_names); # remove name associated with uintptr-t type
  my $args = '';

  for (my $i = 0; $i < @$new_arg_names - 1; $i++) {
    $args .= "$delim$$new_arg_names[$i]";
    $delim = ', ';
  }
  #&dakota::util::add_last($new_arg_names, $last_arg_name); # add name associated with uintptr-t type
  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    $args .= ", $kw_arg_name";
  }
  $$scratch_str_ref .= $col . "static $method_type_decl = $qualified_klass_name\::$method_name; /*qualqual*/\n";
  if ($$method{'return-type'}) {
    $$scratch_str_ref .=
      $col . "$return_type _result_ = $func_name($args);\n" .
      $col . "return _result_;\n";
  } else {
    $$scratch_str_ref .=
      $col . "$func_name($args);\n" .
      $col . "return;\n";
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}\n";
  #&path::remove_last($klass_name);
}
sub dk_generate_cc_footer {
  my ($scope, $stack, $col) = @_;
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  &dk_generate_kw_args_method_defns($scope, $stack, 'trait', $col);
  &dk_generate_kw_args_method_defns($scope, $stack, 'klass', $col);

  if (&is_rt_defn()) {
    my $num_klasses = scalar @$global_klass_defns;
    if (0 == $num_klasses) {
      $$scratch_str_ref .= "\n";
      $$scratch_str_ref .= $col . "static named-info-t* klass-defns = nullptr;\n";
    } else {
      $$scratch_str_ref .= &generate_info_seq('klass-defns', [sort @$global_klass_defns], $col, __LINE__);
    }
    if (0 == keys %{$$scope{'interposers'}}) {
      $$scratch_str_ref .= "\n";
      $$scratch_str_ref .= $col . "static property-t* interposers = nullptr;" . &ann(__FILE__, __LINE__) . "\n";
    } else {
      #print STDERR Dumper $$scope{'interposers'};
      my $interposers = &many_1_to_1_from_1_to_many($$scope{'interposers'});
      #print STDERR Dumper $interposers;

      $$scratch_str_ref .= $col . "static property-t interposers[] = {" . &ann(__FILE__, __LINE__) . " //ro-data\n";
      $col = &colin($col);
      my ($key, $val);
      my $num_klasses = scalar keys %$interposers;
      foreach $key (sort keys %$interposers) {
        $val = $$interposers{$key};
        $$scratch_str_ref .= $col . "{ $key\::__klass__, cast(uintptr-t)$val\::__klass__ },\n";
      }
      $$scratch_str_ref .= $col . "{ nullptr, cast(uintptr-t)nullptr }\n";
      $col = &colout($col);
      $$scratch_str_ref .= $col . "};\n";
    }
  }
  return $$scratch_str_ref;
}
sub dk_generate_kw_args_method_defns {
  my ($scope, $stack, $klass_type, $col) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  while (my ($klass_name, $klass_scope) = each(%{$$scope{$$plural_from_singular{$klass_type}}})) {
    if ($klass_scope && 0 < keys(%$klass_scope)) { #print STDERR &Dumper($klass_scope);
      &path::add_last($stack, $klass_name);
      if (&is_rt_defn()) {
        &dk_generate_cc_footer_klass($klass_scope, $stack, $col, $klass_type, $$scope{'symbols'});
      } else {
        &generate_kw_args_method_signature_defns($$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
        &generate_kw_args_method_defns($$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
      }
      &path::remove_last($stack);
    }
  }
}
sub many_1_to_1_from_1_to_many {
  my ($tbl) = @_;
  my $result = {};
  while (my ($key, $subseq) = each(%$tbl)) {
    my $lhs = $key;
    foreach my $element (@$subseq) {
      my $rhs = $element;
      $$result{$lhs} = $rhs;
      $lhs = $rhs;
    }
  }
  return $result;
}
sub dk_generate_imported_klasses_info {
  my ($scope, $stack, $tbl) = @_;
  if (defined $$scope{'imported-klasses'}) {
    while (my ($import_string, $seq) = each(%{$$scope{'imported-klasses'}})) {
      $$tbl{'imported-klasses'}{$import_string} = $seq;
    }
  }
  foreach my $construct ('traits', 'klasses') {
    while (my ($klass_name, $klass_scope) = each(%{$$scope{$construct}})) {
      &path::add_last($stack, $klass_name);
      my $import_string = &path::string($stack);
      $$tbl{$construct}{$import_string} = &dakota::util::deep_copy($stack);

      if ($klass_scope) {
        $$tbl{'imported-klasses'}{$import_string} = &dakota::util::deep_copy($stack);
      }
      if (defined $$klass_scope{'imported-klasses'}) {
        while (my ($import_string, $seq) = each(%{$$klass_scope{'imported-klasses'}})) {
          $$tbl{'imported-klasses'}{$import_string} = $seq;
        }
      }
      &path::remove_last($stack);
    }
  }
}
sub add_symbol_to_ident_symbol {
  my ($file_symbols, $symbols, $symbol) = @_;
  if ($symbol) {
    my $ident_symbol = &make_ident_symbol_scalar($symbol);
    $$file_symbols{$symbol} = $ident_symbol;
    $$symbols{$symbol} = $ident_symbol;
  }
}
sub should_ann {
  my ($ln, $num_lns, $ann_interval) = @_;
  my $result = 0;
  if (!defined $ann_interval) {
    $ann_interval = $gbl_ann_interval;
  }
  my $num_ann_lns = $num_lns / $ann_interval;
  my $adjusted_ann_interval = ($num_lns / ($num_ann_lns + 1)) + 1;
 #print "ann-interval: " . $ann_interval . "\n"; 
 #print "num-ann-lns: " . $num_lns . ' / ' . $ann_interval . "\n";
 #print "num-ann-lns: " . $num_ann_lns . "\n";
 #print "adjusted-ann-interval: " . $adjusted_ann_interval . "\n";
  $result = 1 if !(($ln + 1) % $adjusted_ann_interval);
  return $result;
}
sub linkage_unit::generate_symbols {
  my ($file, $generics, $symbols) = @_;
  my $col = '';

  while (my ($symbol, $symbol_seq) = each(%$symbols)) {
    my $ident_symbol = &make_ident_symbol($symbol_seq);
    $$symbols{$symbol} = $ident_symbol;
  }
  while (my ($symbol, $symbol_seq) = each(%{$$file{'symbols'}})) {
    &add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $symbol);
  }
  foreach my $klass_type ('klasses', 'traits') {
    foreach my $symbol (keys %{$$file{$klass_type}}) {
      &add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $$file{$klass_type}{$symbol}{'module'});

      if (!exists $$symbols{$symbol}) {
        &add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $symbol);
      }
      my $slots = "$symbol\::slots-t";

      if (!exists $$symbols{$slots}) {
        #&add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $slots);
      }
      my $klass_typedef = "$symbol-t";

      if (!exists $$symbols{$klass_typedef}) {
        &add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $klass_typedef);
      }
    }
  }
  my $symbol_keys = [sort symbol::compare keys %$symbols];
  my $scratch_str = "";
  my $max_width = 0;
  foreach my $symbol (@$symbol_keys) {
    my $ident = &make_ident_symbol_scalar($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  $scratch_str .= $col . 'namespace __symbol {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  my $num_lns = @$symbol_keys;
  while (my ($ln, $symbol) = each @$symbol_keys) {
    my $ident = &make_ident_symbol_scalar($symbol);
    my $width = length($ident);
    my $pad = ' ' x ($max_width - $width);
    if (&is_nrt_decl() || &is_rt_decl()) {
      $scratch_str .= $col . "extern symbol-t $ident;" . "\n";
    } elsif (&is_rt_defn()) {
      $symbol =~ s|"|\\"|g;
      if (&should_ann($ln, $num_lns)) {
        $scratch_str .= $col . "symbol-t $ident = " . $pad . "dk-intern(\"$symbol\");" . &ann(__FILE__, __LINE__) . "\n";
      } else {
        $scratch_str .= $col . "symbol-t $ident = " . $pad . "dk-intern(\"$symbol\");" . "\n";
      }
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  $scratch_str .= "\n";
  return $scratch_str;
}
sub linkage_unit::generate_hashes {
  my ($file, $generics, $symbols) = @_;
  my $col = '';

  my ($symbol, $symbol_seq);
  my $symbol_keys = [sort symbol::compare keys %{$$file{'keywords'}}];
  my $max_width = 0;
  foreach $symbol (@$symbol_keys) {
    my $ident = &make_ident_symbol_scalar($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  my $scratch_str = "";
  if (&is_rt_defn()) {
    $scratch_str .= $col . 'namespace __hash {' . &ann(__FILE__, __LINE__) . "\n";
    $col = &colin($col);
    my $num_lns = @$symbol_keys;
    while (my ($ln, $symbol) = each @$symbol_keys) {
      my $ident = &make_ident_symbol_scalar($symbol);
      my $width = length($ident);
      my $pad = ' ' x ($max_width - $width);
      if (&should_ann($ln, $num_lns)) {
        $scratch_str .= $col . "constexpr uintptr-t $ident = " . $pad . "dk-hash(\"$symbol\");" . &ann(__FILE__, __LINE__) . "\n";
      } else {
        $scratch_str .= $col . "constexpr uintptr-t $ident = " . $pad . "dk-hash(\"$symbol\");" . "\n";
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  }
  return $scratch_str;
}
sub ident_comment {
  my ($ident, $only_if_symbol) = @_;
  my $result = '';
  if (!$only_if_symbol && &needs_hex_encoding($ident)) {
    $result = ' /* ' . $ident . ' */';
  } elsif ($only_if_symbol && $ident =~ m/^#/ && &needs_hex_encoding($ident)) {
    $result = ' /* ' . $ident . ' */';
  }
  return $result;
}
sub linkage_unit::generate_keywords {
  my ($file, $generics, $symbols) = @_;
  my $col = '';

  my ($symbol, $symbol_seq);
  my $symbol_keys = [sort symbol::compare keys %{$$file{'keywords'}}];
  my $max_width = 0;
  foreach $symbol (@$symbol_keys) {
    my $ident = &make_ident_symbol_scalar($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  my $scratch_str = "";

  $scratch_str .= $col . 'namespace __keyword {' . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  my $num_lns = @$symbol_keys;
  while (my ($ln, $symbol) = each @$symbol_keys) {
    my $ident = &make_ident_symbol_scalar($symbol);
    my $width = length($ident);
    my $pad = ' ' x ($max_width - $width);
    if (defined $ident) {
      if (&is_decl()) {
        $scratch_str .= $col . "extern keyword-t $ident;" . "\n";
      } else {
        my $in = &ident_comment($symbol);
        # keyword-defn
        if (&should_ann($ln, $num_lns)) {
          $scratch_str .= $col . "keyword-t $ident = " . $pad . "{ #$symbol, " . $pad . "__hash::$ident };" . $in . &ann(__FILE__, __LINE__) . "\n";
        } else {
          $scratch_str .= $col . "keyword-t $ident = " . $pad . "{ #$symbol, " . $pad . "__hash::$ident };" . $in . "\n";
        }
      }
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . "\n";
  return $scratch_str;
}
sub linkage_unit::generate_strings {
  my ($file, $generics, $strings) = @_;
  my $scratch_str = "";
  my $col = '';
  $scratch_str .= $col . "namespace __string {" . &ann(__FILE__, __LINE__) . "\n";
  $col = &colin($col);
  while (my ($string, $dummy) = each(%{$$file{'strings'}})) {
    my $string_ident = &make_ident_symbol_scalar($string);
    if (&is_decl()) {
      $scratch_str .= $col . "//extern object-t $string_ident;\n";
    } else {
      $scratch_str .= $col . "//object-t $string_ident = make(string::klass, #bytes $colon \"$string\");\n";
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . "}\n";
  return $scratch_str;
}
sub generate_property_tbl {
  my ($name, $tbl, $col, $symbols, $line) = @_;
  #print STDERR &Dumper($tbl);
  my $sorted_keys = [sort keys %$tbl];
  my $num;
  my $result = '';
  my $max_key_width = 0;
  $num = 1;
  foreach my $key (@$sorted_keys) {
    my $element = $$tbl{$key};

    if ('HASH' eq ref $element) {
      $result .= &generate_info("$name-$num", $element, $col, $symbols, $line);
      $element = "&$name-$num";
      $num++;
    } elsif (!defined $element) {
      $element = "nullptr";
    }
    my $key_width = length($key);
    if ($key_width > $max_key_width) {
      $max_key_width = $key_width;
    }
  }
  $result .= "static property-t $name\[] = {" . &ann(__FILE__, $line) . " //ro-data\n";
  $col = &colin($col);
  $num = 1;
  foreach my $key (@$sorted_keys) {
    my $element = $$tbl{$key};

    if ('HASH' eq ref $element) {
      $element = "&$name-$num";
      $num++;
    } elsif (!defined $element) {
      $element = "nullptr";
    }
    my $key_width = length($key);
    my $pad = ' ' x ($max_key_width - $key_width);

    if ($element =~ /^"(.*)"$/) {
      my $element_in = $1;
      if ($$symbols{$element_in}) {
        $element = "\#$element_in";
      } else {
        $element = "dk-intern($element)";
      }
    }
    my $in1 = &ident_comment($key, 1);
    my $in2 = &ident_comment($element, 1);
    $result .= $col . "{ $key, " . $pad . "cast(uintptr-t)$element }," . $in1 . $in2 . "\n";
  }
  $col = &colout($col);
  $result .= $col . "};";
  return $result;
}
sub generate_info {
  my ($name, $tbl, $col, $symbols, $line) = @_;
  my $result = &generate_property_tbl("$name-props", $tbl, $col, $symbols, $line);
  $result .= "\n";
  $result .= $col . "static named-info-t $name = { $name-props, DK-COUNTOF($name-props), nullptr };" . &ann(__FILE__, $line) . "\n";
  return $result;
}
sub generate_info_seq {
  my ($name, $seq, $col, $line) = @_;
  my $result = '';

  $result .= $col . "static named-info-t $name\[] = {" . &ann(__FILE__, $line) . " //ro-data\n";
  $col = &colin($col);

  my $max_width = 0;
  foreach my $element (@$seq) {
    my $width = length($element);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $element (@$seq) {
    my $width = length($element);
    my $pad = ' ' x ($max_width - $width);
    $result .= $col . "{ $element, " . $pad . "DK-COUNTOF($element), " . $pad . "nullptr },\n";
  }
  $result .= $col . "{ nullptr, 0, nullptr }\n";
  $col = &colout($col);
  $result .= $col . "};";
  return $result;
}
sub pad {
  my ($col_num) = @_;
  my $result_str = '';
  $col_num *= 2;
  $result_str .= ' ' x $col_num;
  return $result_str;
}
sub dk_generate_cc {
  my ($file_basename, $path_name) = @_;
  my $filestr = &dakota::util::filestr_from_file("$file_basename.dk");
  my $output = "$path_name.$cc_ext";
  $output =~ s|^\./||;
  my $directory = $ENV{'DKT_DIR'} ||= '.';
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output
  }
  print "    creating $output" . &pann(__FILE__, __LINE__) . "\n"; # user-dk-cc
  my $remove;

  if ($ENV{'DK_NO_LINE'}) {
    &write_to_file_converted_strings("$output", [ $filestr ], $remove = 1);
  } else {
    my $num = 1;
    if ($ENV{'DK_ABS_PATH'}) {
      my $cwd = &getcwd();
      &write_to_file_converted_strings("$output", [ "#line $num \"$cwd/$file_basename.dk\"\n", $filestr ], $remove = 1);
    } else {
      &write_to_file_converted_strings("$output", [ "#line $num \"$file_basename.dk\"\n", $filestr ], $remove = 1);
    }
  }
}
sub start {
  my ($argv) = @_;
  foreach my $in_path (@$argv) {
    my $filestr = &dakota::util::filestr_from_file($in_path);
    my $path;
    &write_to_file_converted_strings($path = undef, [ $filestr ]);
  }
}
unless (caller) {
  &start(\@ARGV);
}
1;
