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

package dakota::generate;

use strict;
use warnings;
use sort 'stable';

my $should_write_pre_output = 1;
my $gbl_ann_interval = 30;

my $emacs_mode_file_variables = '-*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-';

my $gbl_prefix;
my $gbl_compiler;
my $gbl_compiler_default_argument_promotions;
my $builddir;
my $hh_ext;
my $cc_ext;
my $nl = "\n";

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
  unshift @INC, "$gbl_prefix/lib";
  $gbl_compiler = do "$gbl_prefix/lib/dakota/compiler/command-line.json"
    or die "do $gbl_prefix/lib/dakota/compiler/command-line.json failed: $!\n";
  $gbl_compiler_default_argument_promotions = do "$gbl_prefix/lib/dakota/compiler/default-argument-promotions.json"
    or die "do $gbl_prefix/lib/dakota/compiler/default-argument-promotions.json failed: $!\n";
  my $platform = do "$gbl_prefix/lib/dakota/platform.json"
    or die "do $gbl_prefix/lib/dakota/platform.json failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $hh_ext = &dakota::util::var($gbl_compiler, 'hh_ext', undef);
  $cc_ext = &dakota::util::var($gbl_compiler, 'cc_ext', undef);
};
my $use_new_macro_system = 0;

use dakota::rewrite;
use dakota::util;
if ($use_new_macro_system) {
  #use dakota::macro_system;
}

#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use integer;
use Cwd;
use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 empty_klass_defns
                 func::overloadsig
                 generate_src_decl
                 generate_src_defn
                 generate_target_decl
                 generate_target_defn
                 global_scratch_str_ref
                 set_global_scratch_str_ref
                 should_use_include
                 write_to_file_converted_file
              );

my $colon = ':'; # key/element delim only
my $kw_args_placeholders = &kw_args_placeholders();
my ($id,  $mid,  $bid,  $tid,
    $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();

my $global_should_echo = 0;
my $global_is_defn = undef; # klass decl vs defn
my $global_is_target = undef; # <klass>--klasses.{h,cc} vs lib/libdakota--klasses.{h,cc}
my $global_is_exe_target = undef;
my $global_suffix = undef;

my $gbl_src_file = undef;
my $global_scratch_str_ref;
#my $global_src_cc_str;

my $global_seq_super_t =   [ 'super-t' ]; # special (used in eq compare)
my $global_seq_ellipsis =  [ '...' ];
my $global_klass_defns = [];

my $plural_from_singular = { 'klass', => 'klasses', 'trait' => 'traits' };

# not used. left over (converted) from old code gen model
sub src_path {
  my ($name, $ext) = @_;
  $builddir = &dakota::util::builddir();
  if ($ENV{'DK_ABS_PATH'}) {
    my $cwd = &getcwd();
    return "$cwd/$builddir/$name.$ext";
  } else {
    return "$builddir/$name.$ext";
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
sub set_src_decl {
  my ($path) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  $gbl_src_file = &canon_path("$name.dk");
  $global_is_target =   0;
  $global_is_defn = 0;
  $global_suffix = $hh_ext;
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
  $global_suffix = $hh_ext;
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
sub extra_header {
  my ($name) = @_;
  if (&is_decl()) {
    return $nl . "# include <dakota-decl.hh>" . $nl . $nl;
  } elsif (&is_target_defn()) {
    return $nl . "# include \"$name.$hh_ext\"" . $nl . $nl;
  }
  return $nl . "bug-in-code-gen" . $nl;
  # do nothing for rt-defn/rt-cc
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
sub write_to_file_converted_file {
  my ($path_out, $path_in) = @_;
  my $in_str = &dakota::util::filestr_from_file($path_in);
  my $num = 1;
  &write_to_file_converted_strings($path_out, [ "# line $num \"$path_in\"" . $nl, $in_str ]);
}
sub write_to_file_strings {
  my ($path, $strings) = @_;
  &make_dir_part($path, $global_should_echo);
  open PATH, ">$path" or die __FILE__, ":", __LINE__, ": error: \"$path\" $!\n";
  foreach my $string (@$strings) {
    print PATH $string;
  }
  close PATH;
}
my $gbl_macros;
sub write_to_file_converted_strings {
  my ($path, $strings, $remove, $project_ast) = @_;
  if ($use_new_macro_system) {
    if (!defined $gbl_macros) {
      if ($ENV{'DK_MACROS_PATH'}) {
        $gbl_macros = do $ENV{'DK_MACROS_PATH'} or die "do $ENV{'DK_MACROS_PATH'} failed: $!\n";
      } elsif ($gbl_prefix) {
        $gbl_macros = do "$gbl_prefix/lib/dakota/macros.pl" or die "do $gbl_prefix/lib/dakota/macros.pl failed: $!\n";
      } else {
        die;
      }
    }
  }
  if (defined $path) {
    &make_dir_part($path, $global_should_echo);
    open PATH, ">$path" or die __FILE__, ":", __LINE__, ": error: \"$path\" $!\n";
  } else {
    *PATH = *STDOUT;
  }
  my $filestr = '';

  foreach my $string (@$strings) {
    $filestr .= $string;
  }
  my $sst = &sst::make($filestr, ">$path"); # costly (< 1/4 of total)
  my $kw_args_generics = $$project_ast{'kw-args-generics'};
  if ($use_new_macro_system) {
    &dakota::macro_system::macros_expand($sst, $gbl_macros, $kw_args_generics);
  }
  my $converted_string = &sst_fragment::filestr($$sst{'tokens'});
  &dakota::rewrite::convert_dk_to_cc(\$converted_string, $kw_args_generics, $remove); # costly (< 3/4 of total)

  print PATH $converted_string;

  if (defined $path) {
    close PATH;
  }
}
sub generate_src_decl {
  my ($path, $file, $project_ast, $rel_target_hh_path) = @_;
  #print "generate_src_decl($path, ...)" . $nl;
  &set_src_decl($path);
  return &generate_src($path, $file, $project_ast, $rel_target_hh_path);
}
sub generate_src_defn {
  my ($path, $file, $project_ast, $rel_target_hh_path) = @_;
  #print "generate_src_defn($path, ...)" . $nl;
  &set_src_defn($path);
  return &generate_src($path, $file, $project_ast, $rel_target_hh_path);
}
my $im_suffix_for_suffix = {
  $cc_ext => 'cc.dkt',
  $hh_ext => 'hh.dkt',
};
sub pre_output_path_from_any_path {
  my ($path) = @_;
  $path =~ m/\.([\w-]+)$/;
  my $ext = $1;
  my $pre_output_ext = $$im_suffix_for_suffix{$ext};
  die $path if !defined $pre_output_ext;
  my $pre_output = $path =~ s/\.$ext$/.$pre_output_ext/r;
  return $pre_output;
}
sub generate_src {
  my ($path, $file, $project_ast, $rel_target_hh_path) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  my $rel_hh_path = "$name.$hh_ext";
  my $rt = '+srcs';
  my $rel_user_cc_path = $rt . '/' . $name . '.' . $cc_ext;
  #my $user_dir = $dir . '/' . $rt;
  my ($generics, $symbols) = &generics::parse($file);
  my $suffix = &suffix();
  my $output =     "$dir/$name.$suffix";
  my $pre_output = &pre_output_path_from_any_path($output);
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output;
  }
  if (&is_debug()) {
    print "    creating $output" . &pann(__FILE__, __LINE__) . $nl;
  }
  my $str;
  if (&is_src_decl()) {
    $str = &generate_decl_defn($file, $generics, $symbols, $dir, $name, $suffix);
  } else {
    $str = '// ' . $emacs_mode_file_variables  . $nl .
      $nl .
      "# if defined DK_USE_SINGLE_TARGET_HEADER && 0 != DK_USE_SINGLE_TARGET_HEADER" . $nl .
      "# include \"$rel_target_hh_path\"" . $nl .
      "# else" . $nl .
      "# include \"$rel_hh_path\"" . $nl .
      "# endif" . $nl .
      $nl .
      "# include \"$rel_user_cc_path\"" . $nl . # user-code (converted from dk to cc)
      $nl .
      &dk_generate_cc_footer($file);
  }
  if ($should_write_pre_output) {
    &write_to_file_strings($pre_output, [ $str ]);
  }
  my $remove;
  &write_to_file_converted_strings($output, [ $str ], $remove = undef, $project_ast);
  return $output;
} # sub generate_src
sub generate_target_decl {
  my ($path, $file, $project_ast, $is_exe) = @_;
  #print "generate_target_decl($path, ...)" . $nl;
  &set_target_decl($path);
  if ($is_exe) {
    &set_exe_target($path);
  }
  return &generate_target($path, $file, $project_ast);
}
sub generate_target_defn {
  my ($path, $file, $project_ast, $is_exe) = @_;
  #print "generate_target_defn($path, ...)" . $nl;
  &set_target_defn($path);
  if ($is_exe) {
    &set_exe_target($path);
  }
  return &generate_target($path, $file, $project_ast);
}
sub generate_target {
  my ($path, $file, $project_ast) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  my ($generics, $symbols) = &generics::parse($file);
  my $suffix = &suffix();
  my $output =     "$dir/$name.$suffix";
  my $pre_output = &pre_output_path_from_any_path($output);
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output;
  }
  my $start_time;
  my $end_time;
  if (&is_debug()) {
    $start_time = time;
    print "    creating $output" . &pann(__FILE__, __LINE__) . $nl;
  }
  my $str = &generate_decl_defn($file, $generics, $symbols, $dir, $name, $suffix); # costly (> 1/8 of total)

  if (&is_target_defn()) {
    $str .= &generate_target_runtime($file, $generics);
  }
  if ($should_write_pre_output) {
    &write_to_file_strings($pre_output, [ $str ]);
  }
  my $remove;
  &write_to_file_converted_strings($output, [ $str ], $remove = undef, $project_ast);
  if (&is_debug()) {
    $end_time = time;
    my $elapsed_time = $end_time - $start_time;
    print "    creating $output ... done ($elapsed_time secs)" . &pann(__FILE__, __LINE__) . $nl;
  }
  return $output;
} # sub generate_target
sub labeled_src_str {
  my ($tbl, $key) = @_;
  my $str;
  if (! $tbl) {
    #$key = uc($key);
    $str = "# undef $key" . $nl;
  } else {
    $str = "# undef $key" . $nl;
    $str .= $$tbl{$key};
    if (!exists $$tbl{$key}) {
      print STDERR "NO SUCH KEY $key\n";
    }
    $str .= "//--$key-end--" . $nl;
  }
  return $str;
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
sub add_labeled_src {
  my ($result, $label, $src) = @_;
  if (!$$result{'--labels'}) { $$result{'--labels'} = []; }
  &dakota::util::add_last($$result{'--labels'}, $label);
  $$result{$label} = $src;
}
sub generate_decl_defn {
  my ($file, $generics, $symbols, $dir, $name, $suffix) = @_;
  my $result = {};
  my $extra_header = &extra_header($name);
  my $ordered_klass_names = &order_klasses($file);

  &add_labeled_src($result, "headers-$suffix",    &linkage_unit::generate_headers(   $file, $ordered_klass_names, $extra_header));
  &add_labeled_src($result, "symbols-$suffix",    &linkage_unit::generate_symbols(   $file, $symbols));
  &add_labeled_src($result, "klasses-$suffix",    &linkage_unit::generate_klasses(   $file, $ordered_klass_names));
 #&add_labeled_src($result, "hashes-$suffix",     &linkage_unit::generate_hashes(    $file));
  &add_labeled_src($result, "keywords-$suffix",   &linkage_unit::generate_keywords(  $file));
  &add_labeled_src($result, "strs-$suffix",       &linkage_unit::generate_strs(      $file));
  &add_labeled_src($result, "ints-$suffix",       &linkage_unit::generate_ints(      $file));
  &add_labeled_src($result, "selectors-$suffix",  &linkage_unit::generate_selectors( $generics));
  &add_labeled_src($result, "signatures-$suffix", &linkage_unit::generate_signatures($generics));
  my $col = '';
  my $output_base = "$name-generic-func-defns";
  my $rel_hh_path = "$output_base.$hh_ext";
  if (&is_target_defn()) {
    my $output = "$dir/$rel_hh_path";
    my $strings = [ '// ', $emacs_mode_file_variables, "\n\n", &linkage_unit::generate_generics($generics, $col) ];
    if ($should_write_pre_output) {
      my $pre_output = &pre_output_path_from_any_path($output);
      &write_to_file_strings($pre_output, $strings);
    }
    &write_to_file_converted_strings($output, $strings);
    &add_labeled_src($result, "generics-$suffix",
                     "# if !defined DK-INLINE-GENERIC-FUNCS" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$rel_hh_path\"" . $nl .
                     "# endif" . $nl);
  } elsif (&is_src_decl() || &is_target_decl()) {
    &add_labeled_src($result, "generics-$suffix",
                     "# if defined DK-INLINE-GENERIC-FUNCS" . $nl .
                     "  # define INLINE inline" . $nl .
                     "  # include \"$rel_hh_path\"" . $nl .
                     "# else" . $nl .
                     "  # define INLINE" . $nl .
                     &linkage_unit::generate_generics($generics, &colin($col)) .
                     "# endif" . $nl);
  }

  my $is_inline;
  my $str = '// ' . $emacs_mode_file_variables  . $nl .
    $nl .
    &labeled_src_str($result, "headers-$suffix") .
    &labeled_src_str($result, "symbols-$suffix") .
    &labeled_src_str($result, "klasses-$suffix") .
   #&labeled_src_str($result, "hashes-$suffix") .
    &labeled_src_str($result, "keywords-$suffix") .
    &labeled_src_str($result, "strs-$suffix") .
    &labeled_src_str($result, "ints-$suffix") .
    &labeled_src_str($result, "selectors-$suffix") .
    &labeled_src_str($result, "signatures-$suffix") .
    &labeled_src_str($result, "generics-$suffix");

  return $str;
} # generate_decl_defn
sub generate_target_runtime {
  my ($file, $generics) = @_;
  my $target_cc_str = '';
  my $col = '';
  my $keys_count = keys %{$$file{'klasses'}};
  if (0 == $keys_count) {
    $target_cc_str .= $col . "static const symbol-t* imported-klass-names = nullptr;" . $nl;
    $target_cc_str .= $col . "static assoc-node-t*   imported-klass-ptrs =  nullptr;" . $nl;
  } else {
    $target_cc_str .= $col . "static symbol-t imported-klass-names[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    my $num_klasses = scalar keys %{$$file{'klasses'}};
    foreach my $klass_name (sort keys %{$$file{'klasses'}}) {
      $target_cc_str .= $col . "$klass_name\::__klass__," . $nl;
    }
    $target_cc_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $target_cc_str .= $col . "};" . $nl;
    ###
    $target_cc_str .= $col . "static assoc-node-t imported-klass-ptrs[] = {" . &ann(__FILE__, __LINE__) . " //rw-data" . $nl;
    $col = &colin($col);
    $num_klasses = scalar keys %{$$file{'klasses'}};
    foreach my $klass_name (sort keys %{$$file{'klasses'}}) {
      $target_cc_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)&$klass_name\::klass }," . $nl;
    }
    $target_cc_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)nullptr }" . $nl;
    $col = &colout($col);
    $target_cc_str .= $col . "};" . $nl;
    $target_cc_str .= &linkage_unit::generate_target_runtime_selectors_seq( $generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_signatures_seq($generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_generic_func_ptrs_seq($generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_strs_seq($file);
    $target_cc_str .= &linkage_unit::generate_target_runtime_ints_seq($file);

    $target_cc_str .= &dk_generate_cc_footer($file);
  }
  #$target_cc_str .= $col . "extern \"C\$nl;
  #$target_cc_str .= $col . "{" . $nl;
  #$col = &colin($col);

  my $info_tbl = {
                  "\#dir" => 'dir',
                  "\#file" => '__FILE__',
                  "\#generic-func-ptrs" => 'generic-func-ptrs',
                  "\#get-segment-data" => 'dkt-get-segment-data',
                  "\#imported-klass-names" => 'imported-klass-names',
                  "\#imported-klass-ptrs" =>  'imported-klass-ptrs',
                  "\#interposers" => 'interposers',
                  "\#klass-defns" => 'klass-defns',
                  "\#name" => 'name',
                  "\#selectors" =>  'selectors',
                  "\#signatures" => 'signatures',
                  "\#type" => $$file{'other'}{'type'},
                  "\#va-generic-func-ptrs" => 'va-generic-func-ptrs',
                  "\#va-selectors" =>  'va-selectors',
                  "\#va-signatures" => 'va-signatures',
                 };
  if (0 < scalar keys %{$$file{'literal-strs'}}) {
    $$info_tbl{"\#str-literals"} = '__str-literals';
    $$info_tbl{"\#str-names"} =    '__str-names';
    $$info_tbl{"\#str-ptrs"} =     '__str-ptrs';
  }
  if (0 < scalar keys %{$$file{'literal-ints'}}) {
    $$info_tbl{"\#int-literals"} = '__int-literals';
    $$info_tbl{"\#int-names"} =    '__int-names';
    $$info_tbl{"\#int-ptrs"} =     '__int-ptrs';
  }
  $target_cc_str .= $nl;
  $target_cc_str .= "# include <unistd.h>" . $nl;
  $target_cc_str .= $nl;
  $target_cc_str .= "[[read-only]] static char8-t  dir-buffer[4096] = \"\";" . $nl;
  $target_cc_str .= "[[read-only]] static str-t    dir = getcwd(dir-buffer, countof(dir-buffer));" . $nl;
  $target_cc_str .= "[[read-only]] static symbol-t name = \"$$file{'other'}{'name'}\";" . $nl;
  $target_cc_str .= $nl;
  #my $col;
  $target_cc_str .= &generate_target_runtime_info('reg-info', $info_tbl, $col, $$file{'symbols'}, __LINE__);

  $target_cc_str .= $nl;
  $target_cc_str .= $col . "static func __initial() -> void {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  $target_cc_str .=
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"before\", dir, name);" . $nl .
    $col . "dkt-register-info(&reg-info);" . $nl .
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"after\",  dir, name);" . $nl .
    $col . "return;" . $nl;
  $col = &colout($col);
  $target_cc_str .= $col . "}" . $nl;
  $target_cc_str .= $col . "static func __final() -> void {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  $target_cc_str .=
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"before\", dir, name);" . $nl .
    $col . "dkt-deregister-info(&reg-info);" . $nl .
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"after\",  dir, name);" . $nl .
    $col . "return;" . $nl;
  $col = &colout($col);
  $target_cc_str .= $col . "}" . $nl;
  #$col = &colout($col);
  #$target_cc_str .= $col . "};" . $nl;

  $target_cc_str .=
    $col . "namespace { struct [[gnu::visibility(\"hidden\")]] __ddl_t {" . &ann(__FILE__, __LINE__) . $nl .
    $col . "  __ddl_t(const __ddl_t&) = default;" . $nl .
    $col . "  __ddl_t()  { __initial(); }" . $nl .
    $col . "  ~__ddl_t() { __final();   }" . $nl .
    $col . "};}" . $nl .
    $col . "static __ddl_t __ddl = __ddl_t();" . $nl;
  return $target_cc_str;
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
sub arg::type {
  my ($arg) = @_;
  if (!defined $arg) {
    $arg = [ 'void' ];
  }
  $arg = join(' ', @$arg);
  $arg = &remove_extra_whitespace($arg);
  return $arg;
}
sub arg_type::super {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;

  my $new_arg_type_ref = &dakota::util::deep_copy($arg_type_ref);

  #if (object-t eq $$new_arg_type_ref[0]) {
  $$new_arg_type_ref[0] = $global_seq_super_t; # replace_first
  #} else {
  #    $$new_arg_type_ref[0] = 'UNKNOWN-T';
  #}
  return $new_arg_type_ref;
}
sub arg_type::var_args {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;

  my $new_arg_type_ref = &dakota::util::deep_copy($arg_type_ref);
  die if 'va-list-t' ne &ct($$new_arg_type_ref[-1]);
  $$new_arg_type_ref[$num_args - 1] = $global_seq_ellipsis;
  return $new_arg_type_ref;
}
sub arg_type::names {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;
  my $arg_num =        0;
  my $arg_names = [];

  if (&ct($global_seq_super_t) eq &ct($$arg_type_ref[0])) {
    $$arg_names[0] = "context";    # replace_first
  } else {
    $$arg_names[0] = 'object';  # replace_first
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    if (&ct($global_seq_ellipsis) eq &ct($$arg_type_ref[$arg_num])) {
      $$arg_names[$arg_num] = undef;
    } elsif ('va-list-t' eq &ct($$arg_type_ref[$arg_num])) {
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
  my $type_str = &ct($type_seq);

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
  my $num_args =       @$arg_type_ref;
  my $arg_num =        0;
  my $arg_names = [];

  if ('slots-t*' eq &ct($$arg_type_ref[0])) {
    $$arg_names[0] = '&unbox(object)';
  } elsif ('slots-t' eq &ct($$arg_type_ref[0])) {
    $$arg_names[0] = 'unbox(object)';
  } elsif ('slots-t&' eq &ct($$arg_type_ref[0])) {
    $$arg_names[0] = 'unbox(object)';
  } else {
    $$arg_names[0] = 'object';
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    if ('slots-t*' eq &ct($$arg_type_ref[$arg_num])) {
      $$arg_names[$arg_num] = "\&unbox(arg$arg_num)";
    } elsif ('slots-t' eq &ct($$arg_type_ref[$arg_num])) {
      $$arg_names[$arg_num] = "unbox(arg$arg_num)";
    } elsif ('slots-t&' eq &ct($$arg_type_ref[$arg_num])) {
      $$arg_names[$arg_num] = "unbox(arg$arg_num)";
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
  my $list =          '';
  my $arg_num;
  my $delim = '';
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
  my $num_args =   @$args_ref;
  my $list =       '';
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
  my $num_args =   @$args_ref;
  my $list =       '';
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
      $delim = ', '; # extra whitespace
    }
  }
  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    my $kw_arg_type = &arg::type($$kw_arg{'type'});

    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default_placeholder = $$kw_args_placeholders{'default'};
      $result .= "$delim$kw_arg_type $kw_arg_name:$kw_arg_default_placeholder"; # extra whitespace
    } else {
      $result .= "$delim$kw_arg_type $kw_arg_name:"; # extra whitespace
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
  my $num_args =    @$args_ref;
  my $num_kw_args = @$kw_args_ref;
  my $list =        '';
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
sub func::decl {
  my ($func, $scope) = @_;
  my $func_decl = '';

  my $visibility = '';
  if (&is_exported($func)) {
    $visibility = '[[export]] ';
  }
  my $func_spec = '';
  if ($$func{'inline?'}) {
    $func_spec = 'INLINE ';
  }
  my $return_type = &arg::type($$func{'return-type'});
  my ($name, $parameter_types) = &func::overloadsig_parts($func, $scope);
  $func_decl .= $func_spec . "$name($parameter_types) -> $return_type;";
  return ($visibility, \$func_decl);
}
sub func::overloadsig_parts {
  my ($func, $scope) = @_;
  my $last_element = $$func{'parameter-types'}[-1];
  my $last_type = &arg::type($last_element);
  my $name = &ct($$func{'name'} ||= []); # rnielsenrnielsen hackhack
  #if ($name eq '') { return undef; }
  my $parameter_types = &arg_type::list_types($$func{'parameter-types'});
  return ($name, $$parameter_types);
}
sub func::overloadsig {
  my ($func, $scope) = @_;
  my ($name, $parameter_types) = &func::overloadsig_parts($func, $scope);
  my $func_overloadsig = "$name($parameter_types)";
  return $func_overloadsig;
}
sub method::var_args_from_qual_va_list {
  my ($method) = @_;
  my $new_method = &dakota::util::deep_copy($method);

  if ('va' eq $$new_method{'name'}[0]) {
    &remove_name_va_scope($new_method);
  }
  if (exists $$new_method{'parameter-types'}) {
    &dakota::util::_replace_last($$new_method{'parameter-types'}, ['...']);
  }
  return $new_method;
}
sub generate_va_generic_defn {
  #my ($scope, $va_method) = @_;
  my ($va_method, $scope, $col, $klass_type, $line) = @_;
  my $is_inline =  $$va_method{'inline?'};

  my $new_arg_types_ref =      $$va_method{'parameter-types'};
  my $new_arg_types_va_ref =   &arg_type::var_args($new_arg_types_ref);
  my $new_arg_names_ref =      &arg_type::names($new_arg_types_ref);
  my $new_arg_names_va_ref =   &arg_type::names($new_arg_types_va_ref);
  my $new_arg_list_va_ref =    &arg_type::list_pair($new_arg_types_va_ref, $new_arg_names_va_ref);
  my $new_arg_names_list_ref = &arg_type::list_names($new_arg_names_ref);

  my $num_args = @$new_arg_names_va_ref;
  my $return_type = &arg::type($$va_method{'return-type'});
  my $va_method_name;

  #if ($$va_method{'alias'}) {
  #$va_method_name = &ct($$va_method{'alias'});
  #}
  #else {
  $va_method_name = &ct($$va_method{'name'});
  #}
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($klass_type) {
    $$scratch_str_ref .= $col . $klass_type . " @$scope { ";
  }
  else {
    $$scratch_str_ref .= $col . "namespace" . " @$scope { ";
  }
  my $vararg_method = &deep_copy($va_method);
  $$vararg_method{'parameter-types'} = &arg_type::var_args($$vararg_method{'parameter-types'});
  my $visibility = '';
  if (&is_exported($va_method)) {
    $visibility = '[[export]] ';
  }
  if (&is_kw_args_generic($vararg_method)) {
    $$scratch_str_ref .= '[[sentinel]] ';
  }
  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= 'extern ';
  }
  my $func_spec = '';
  if ($is_inline) {
    $func_spec = 'INLINE ';
  }
  $$scratch_str_ref .= $visibility . $func_spec;
  if ($klass_type) {
    $$scratch_str_ref .= 'METHOD ';
  }
  else {
    $$scratch_str_ref .= 'func ';
  }
  $$scratch_str_ref .= "$va_method_name($$new_arg_list_va_ref) -> $return_type";

  if (!$$va_method{'defined?'} || &is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= "; }" . &ann(__FILE__, $line) . $nl;
  } elsif ($$va_method{'defined?'} && (&is_target_defn())) {
    my $name = &dakota::util::last($$va_method{'name'});
    my $va_name = "_func_";
    &dakota::util::_replace_last($$va_method{'name'}, $va_name);
    my $method_type_decl = &method::type_decl($va_method);
    &dakota::util::_replace_last($$va_method{'name'}, $name);
    my $scope_str = &ct($scope);
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .=
      $col . "static func $method_type_decl = $scope_str\::va::$va_method_name;" . $nl .
      $col . "va-list-t args;" . $nl .
      $col . "va-start(args, $$new_arg_names_ref[$num_args - 2]);" . $nl;

    if (defined $$va_method{'return-type'}) {
      my $return_type = &arg::type($$va_method{'return-type'});
      $$scratch_str_ref .= $col . "$return_type result = ";
    } else {
      $$scratch_str_ref .= $col . "";
    }

    $$scratch_str_ref .=
      "$va_name($$new_arg_names_list_ref);" . $nl .
      $col . "va-end(args);" . $nl;

    if (defined $$va_method{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;" . $nl;
    } else {
      $$scratch_str_ref .= $col . "return;" . $nl;
    }
    $col = &colout($col);
    $$scratch_str_ref .= $col . "}}" . $nl;
  }
}
sub method::compare {
  my $scope;
  my $a_string = &func::overloadsig($a, $scope = []); # the a and b values sometimes
  my $b_string = &func::overloadsig($b, $scope = []); # are missing the 'name' key

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
    my $arg_type = &ct($arg_type_ref);
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
    $scratch_str .= $col . 'namespace va { func ';
  } else {
    $scratch_str .= $col . 'func ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = '[[export]] ';
  }
  my $generic_name = &ct($$generic{'name'});
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . "$generic_name($$new_arg_type_list) -> const signature-t*";
  if (&is_src_decl() || &is_target_decl()) {
    if (&is_va($generic)) {
      $scratch_str .= '; }' . $nl;
    } else {
      $scratch_str .= ';' . $nl;
    }
  } elsif (&is_target_defn()) {
    $scratch_str .= ' {' . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);

    my $return_type_str = &arg::type($$generic{'return-type'});
    my $name_str;
    if (&is_va($generic)) {
      $name_str = "va::$generic_name";
    } else {
      $name_str = "$generic_name";
    }
    my $padlen = length($col);
    $padlen += length("static const signature-t result = { ");
    my $arg_list =    "static const signature-t result = { .name =            \"$name_str\"," . $nl .
      (' ' x $padlen) . ".parameter-types = \"$$new_arg_type_list\"," . $nl .
      (' ' x $padlen) . ".return-type =     \"$return_type_str\" };" . $nl;
    $scratch_str .=
      $col . "$arg_list" . $nl .
      $col . "return &result;" . $nl;
    $col = &colout($col);

    if (&is_va($generic)) {
      $scratch_str .= $col . '}}' . $nl;
    } else {
      $scratch_str .= $col . '}' . $nl;
    }
  }
  return $scratch_str;
}
sub common::generate_signature_defns {
  my ($generics, $col) = @_;
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_signature_defns()" . $nl;

  $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . $nl;
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
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;

  if (1) {
    $scratch_str .= "# if 0" . $nl;
    $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $generic (sort method::compare @$generics) {
      if (&is_va($generic)) {
        my $var_args_generic = &method::var_args_from_qual_va_list($generic);
        my $keyword_types = $$var_args_generic{'keyword-types'} ||= undef;
        #if (!&is_slots($var_args_generic)) {
        $scratch_str .= &common::print_signature($var_args_generic, $col, ['signature']);
        #}
        $$var_args_generic{'keyword-types'} = $keyword_types;
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
    $scratch_str .= "# endif" . $nl;
  } # if ()
  $scratch_str .= $col . 'namespace __signature {' . &ann(__FILE__, __LINE__) . $nl;
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
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  return $scratch_str;
}
sub common::print_selector {
  my ($generic, $col, $path) = @_;
  my $new_arg_type = $$generic{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $$new_arg_type_list = &remove_extra_whitespace($$new_arg_type_list);

  my $scratch_str = "";
  if (&is_va($generic)) {
    $scratch_str .= $col . 'namespace va { func ';
  } else {
    $scratch_str .= $col . 'func ';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = '[[export]] ';
  }
  my $generic_name = &ct($$generic{'name'});
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . "$generic_name($$new_arg_type_list) -> selector-t*";
  if (&is_src_decl() || &is_target_decl()) {
    if (&is_va($generic)) {
      $scratch_str .= '; }' . $in . $nl;
    } else {
        $scratch_str .= ';' . $in . $nl;
    }
  } elsif (&is_target_defn()) {
    $scratch_str .= ' {' . $in . $nl;
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

    $scratch_str .= $col . "[[read-only]] static selector-t result = $null_selector;" . $nl;
    $scratch_str .= $col . "return &result;" . $nl;
    $col = &colout($col);
    if (&is_va($generic)) {
      $scratch_str .= $col . '}}' . $nl;
    } else {
      $scratch_str .= $col . '}' . $nl;
    }
  }
  return $scratch_str;
}
sub common::generate_selector_defns {
  my ($generics, $col) = @_;
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_selector_defns()" . $nl;

  $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . $nl;
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
  $scratch_str .= $col . '}' . $nl;

  if (1) {
    $scratch_str .= "# if 0" . $nl;
    $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $generic (sort method::compare @$generics) {
      if (&is_va($generic)) {
        my $var_args_generic = &method::var_args_from_qual_va_list($generic);
        my $keyword_types = $$var_args_generic{'keyword-types'} ||= undef;
        if (!&is_slots($generic)) {
          $scratch_str .= &common::print_selector($var_args_generic, $col, ['__selector']);
        }
        $$var_args_generic{'keyword-types'} = $keyword_types;
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . $nl;
    $scratch_str .= "# endif" . $nl;
  } # if ()
  $scratch_str .= $col . 'namespace __selector {' . &ann(__FILE__, __LINE__) . $nl;
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
  $scratch_str .= $col . '}' . $nl;
  return $scratch_str;
}

my $global_prev_io;
sub va_generics {
  my ($generics, $name) = @_;
  my $va_generics = [];
  my $fa_generics = [];
  foreach my $generic (sort method::compare @$generics) {
    if (!$name || $name eq &ct($$generic{'name'})) {
      if (&is_va($generic)) {
        &dakota::util::add_last($va_generics, $generic);
      } else {
        &dakota::util::add_last($fa_generics, $generic);
      }
    }
  }
  return ($va_generics, $fa_generics);
}
sub linkage_unit::generate_target_runtime_generic_func_ptrs_seq {
  my ($generics) = @_;
  my $col = '';
  my ($va_generics, $fa_generics) = &va_generics($generics, undef);
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_target_runtime_generic_func_ptrs_seq()" . $nl;
  my $generic;
  my $i;
  my $return_type = 'generic-func-t*';

  if (0 == @$va_generics) {
    $scratch_str .= $col . "static generic-func-t** va-generic-func-ptrs = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static generic-func-t* va-generic-func-ptrs[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list = &arg_type::list_types($$generic{'parameter-types'});
      my $generic_name = &ct($$generic{'name'});
      my $in = &ident_comment($generic_name);
      $scratch_str .= $col . "GENERIC-FUNC-PTR-PTR(va::$generic_name($$new_arg_type_list))," . $in . $nl;
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static generic-func-t** generic-func-ptrs = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static generic-func-t* generic-func-ptrs[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list = &arg_type::list_types($$generic{'parameter-types'});
        my $generic_name = &ct($$generic{'name'});
        my $in = &ident_comment($generic_name);
        $scratch_str .= $col . "GENERIC-FUNC-PTR-PTR($generic_name($$new_arg_type_list))," . $in . $nl;
      }
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub generics::generate_signature_seq {
  my ($generics, $is_inline, $col) = @_;
  my ($va_generics, $fa_generics) = &va_generics($generics, undef);
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_signature_seq()" . $nl;
  my $generic;
  my $i;
  my $return_type = 'const signature-t*';

  if (0 == @$va_generics) {
    $scratch_str .= $col . "static const signature-t* const* va-signatures = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static const signature-t* const va-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list = &arg_type::list_types($$generic{'parameter-types'});
      my $generic_name = &ct($$generic{'name'});
      my $in = &ident_comment($generic_name);
      $scratch_str .= $col . "SIGNATURE(va::$generic_name($$new_arg_type_list))," . $in . $nl;
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static const signature-t* const* signatures = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static const signature-t* const signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list = &arg_type::list_types($$generic{'parameter-types'});
        my $generic_name = &ct($$generic{'name'});
        my $in = &ident_comment($generic_name);
        $scratch_str .= $col . "SIGNATURE($generic_name($$new_arg_type_list))," . $in . $nl;
      }
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub generics::generate_selector_seq {
  my ($generics, $is_inline, $col) = @_;
  my ($va_generics, $fa_generics) = &va_generics($generics, undef);
  my $scratch_str = "";
  #$scratch_str .= $col . "// generate_selector_seq()" . $nl;
  my $generic;
  my $i;
  my $return_type = "selector-t*";

  if (0 == @$va_generics) {
    $scratch_str .= $col . "static selector-node-t* va-selectors = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static selector-node-t va-selectors[] = {" . &ann(__FILE__, __LINE__) . " //rw-data" . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list =   &arg_type::list_types($$generic{'parameter-types'});
      my $name = &ct($$generic{'name'});
      my $in = &ident_comment($name);
      $scratch_str .= $col . "{ .next = nullptr, .ptr = SELECTOR-PTR(va::$name($$new_arg_type_list)) }," . $in . $nl;
    }
    $scratch_str .= $col . "{ .next = nullptr, .ptr = nullptr }," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static selector-node-t* selectors = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static selector-node-t selectors[] = {" . &ann(__FILE__, __LINE__) . " //rw-data" . $nl;
    $col = &colin($col);
    foreach $generic (@$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list =   &arg_type::list_types($$generic{'parameter-types'});
        my $name = &ct($$generic{'name'});
        my $in = &ident_comment($name);
        $scratch_str .= $col . "{ .next = nullptr, .ptr = SELECTOR-PTR($name($$new_arg_type_list)) }," . $in . $nl;
      }
    }
    $scratch_str .= $col . "{ .next = nullptr, .ptr = nullptr }," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub generate_va_generic_defns {
  my ($generics, $is_inline, $col, $ns) = @_;
  foreach my $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      my $scope = [];
      &path::add_last($scope, $ns);
      my $new_generic = &dakota::util::deep_copy($generic);
      $$new_generic{'inline?'} = $is_inline;

      $$new_generic{'defined?'} = 1; # hackhack

      my $klass_type;
      &generate_va_generic_defn($new_generic, $scope, $col, $klass_type = undef, __LINE__); # object-t
      $$new_generic{'parameter-types'}[0] = $global_seq_super_t; # replace_first
      &generate_va_generic_defn($new_generic, $scope, $col, $klass_type = undef, __LINE__); # super-t
      &path::remove_last($scope);
    }
  }
}
sub is_super {
  my ($generic) = @_;
  if ('super-t' eq $$generic{'parameter-types'}[0][0]) {
    return 1;
  }
  return 0;
}
my $big_generic = 0;
sub generate_generic_defn {
  my ($generic, $is_inline, $col, $ns) = @_;
  my $generic_name = $$generic{'name'}[0];
  my $orig_arg_type_list = &arg_type::list_types($$generic{'parameter-types'});
  my $tmp = $$generic{'parameter-types'}[0][0];
  $$generic{'parameter-types'}[0][0] = 'object-t';
  my $new_arg_type =            $$generic{'parameter-types'};
  my $new_arg_type_list =   &arg_type::list_types($new_arg_type);
  $$generic{'parameter-types'}[0][0] = $tmp;
  $new_arg_type =            $$generic{'parameter-types'};
  my $new_arg_names =           &arg_type::names($new_arg_type);
  my $new_arg_list =            &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$generic{'return-type'});
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = 'namespace va { ';
    $opt_va_prefix = 'va::';
    $opt_va_close = '}'
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  my $in = &ident_comment($generic_name);
  $$scratch_str_ref .= $col . '// dk::' . $opt_va_prefix . $generic_name . '(' . $$orig_arg_type_list . ')' . ' -> ' . $return_type . $nl;
  $$scratch_str_ref .= $col . 'namespace __generic-func { ' . $opt_va_open . 'static INLINE func ' . $generic_name . '(' . $$new_arg_list . ") -> $return_type";

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= "; }" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    if ($big_generic) {
      $$scratch_str_ref .= $col . "DEBUG-STMT(static const signature-t* signature = SIGNATURE($opt_va_prefix$generic_name($$new_arg_type_list)));" . $nl;
    }
    my $signature;
    $signature = "SIGNATURE($opt_va_prefix$generic_name($$new_arg_type_list))";
    $$scratch_str_ref .= $col . "static selector-t selector = SELECTOR($opt_va_prefix$generic_name($$new_arg_type_list));" . $nl;
    $$scratch_str_ref .= $col . "typealias func-t = func (*)($$new_arg_type_list) -> $return_type;" . ' // no runtime cost' . $nl;
    if (&is_super($generic)) {
      $$scratch_str_ref .= $col . "func-t _func_ = cast(func-t)klass::unbox(superklass-of(context.klass)).methods.addrs[selector];" . $nl;
      $$scratch_str_ref .= $col . "DEBUG-STMT(if (DKT-NULL-METHOD == cast(method-t)_func_)" . $nl;
      $col = &colin($col);
      $$scratch_str_ref .= $col . "dkt-throw-no-such-method-exception(context, $signature));" . $nl;
      $col = &colout($col);
    } else {
      $$scratch_str_ref .= $col . "func-t _func_ = cast(func-t)klass::unbox(klass-of(object)).methods.addrs[selector];" . $nl;
      $$scratch_str_ref .= $col . "DEBUG-STMT(if (DKT-NULL-METHOD == cast(method-t)_func_)" . $nl;
      $col = &colin($col);
      $$scratch_str_ref .= $col . "dkt-throw-no-such-method-exception(object, $signature));" . $nl;
      $col = &colout($col);
    }
    my $arg_names_list;
    if ($big_generic) {
      my $arg_names = &dakota::util::deep_copy(&arg_type::names(&dakota::util::deep_copy($$generic{'parameter-types'})));
      $arg_names_list = &arg_type::list_names($arg_names);

      if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
        $$scratch_str_ref .= $col . "DKT-TRACE-BEFORE(signature, cast(method-t)_func_, $$arg_names_list, nullptr);" . $nl;
      }
    }
    if (&is_super($generic)) {
      $new_arg_type = &arg_type::super($new_arg_type);
    }
    $new_arg_names = &arg_type::names($new_arg_type);
    if (&is_super($generic)) {
      &dakota::util::_replace_first($new_arg_names, "context.object");
    }
    my $new_arg_names_list = &arg_type::list_names($new_arg_names);

    $$scratch_str_ref .= $col . "return _func_($$new_arg_names_list);" . $nl;
    if ($big_generic) {
      if ($ENV{'DK_ENABLE_TRACE_MACROS'}) {
        my $result = 'result';
        if ($$arg_names_list =~ m/,/) {
          $$arg_names_list =~ s/^(.+?),\s*(.*)$/$1, $result, $2/;
        } else {
          $$arg_names_list .= ", $result";
        }
        $$scratch_str_ref .= $col . "DKT-TRACE-AFTER(signature, _func_, $$arg_names_list, nullptr);" . $nl;
      }
    }
    $col = &colout($col);
    $$scratch_str_ref .= $col . '}}' . $opt_va_close . $nl;
  }
} # generate_generic_defn
sub generate_generic_func_ptr_defn {
  my ($generic, $is_inline, $col, $ns) = @_;
  my $generic_name = $$generic{'name'}[0];
  my $list_types_str_ref = &arg_type::list_types($$generic{'parameter-types'});
  my $return_type_str = &remove_extra_whitespace(join(' ', @{$$generic{'return-type'}}));
  my $in = &ident_comment($generic_name);
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = 'namespace va { ';
    $opt_va_prefix = 'va::';
    $opt_va_close = '}'
  }
  #namespace __generic-func-ptr { INLINE func add(object-t, object-t) -> generic-func-t* {
  #  typealias func-t = func (*)(object-t, object-t) -> object-t; // no runtime cost
  #    static generic-func-t result = cast(generic-func-t)cast(func-t)__generic-func::add;
  #  return &result;
  #}}
  my $scratch_str_ref = &global_scratch_str_ref();
  $$scratch_str_ref .= $col . 'namespace __generic-func-ptr { ' . $opt_va_open . 'static INLINE func ' . $generic_name . '(' . $$list_types_str_ref . ') -> generic-func-t*';

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= "; }" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .= $col . "typealias func-t = func (\*)($$list_types_str_ref) -> $return_type_str;" . ' // no runtime cost' . $nl;
    $$scratch_str_ref .= $col . 'static generic-func-t result = cast(generic-func-t)cast(func-t)(__generic-func::' . $opt_va_prefix . $generic_name . ');' . $nl;
    $$scratch_str_ref .= $col . 'return &result;' . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . '}}' . $opt_va_close . $nl;
  }
}
sub generate_generic_func_defn {
  my ($generic, $is_inline, $col, $ns) = @_;
  my $generic_name = $$generic{'name'}[0];
  my $list_types_str_ref = &arg_type::list_types($$generic{'parameter-types'});
  my $list_names = &arg_type::names($$generic{'parameter-types'});
  my $list_names_str =  &remove_extra_whitespace(join(', ', @$list_names));
  my $arg_list =  &arg_type::list_pair($$generic{'parameter-types'}, $list_names);
  my $return_type_str = &remove_extra_whitespace(join(' ', @{$$generic{'return-type'}}));
  my $in = &ident_comment($generic_name);
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = 'namespace va { ';
    $opt_va_prefix = 'va::';
    $opt_va_close = '}'
  }
  #namespace dk { INLINE generic-func add(object-t arg0, object-t arg1) -> object-t {
  #  typealias func-t = func (*)(object-t, object-t) -> object-t; // no runtime cost
  #  func-t _func_ = cast(func-t)GENERIC-FUNC(add(object-t, object-t)); // static would be faster, but more rigid
  #  return _func_(arg0, arg1);
  #}}
  my $scratch_str_ref = &global_scratch_str_ref();
  $$scratch_str_ref .= $col . 'namespace dk { ' . $opt_va_open . 'INLINE func ' . $generic_name . '(' . $$arg_list . ') -> ' . $return_type_str;

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= "; }" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .= $col . "typealias func-t = func (\*)($$list_types_str_ref) -> $return_type_str;" . ' // no runtime cost' . $nl;
    $$scratch_str_ref .= $col . 'func-t _func_ = cast(func-t)GENERIC-FUNC-PTR(' . $opt_va_prefix . $generic_name . '(' . $$list_types_str_ref . '));' . $nl;
    $$scratch_str_ref .= $col . 'return _func_(' . $list_names_str . ');' . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . '}}' . $opt_va_close . $nl;
  }
}
sub generate_generic_defns {
  my ($generics, $is_inline, $col, $ns) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_generic_defns()" . $nl;
  my $generic;
  #$$scratch_str_ref .= "# if defined DKT-VA-GENERICS" . $nl;
  $$scratch_str_ref .= $col . &labeled_src_str(undef, "va-generics-object-t" . '-' . &suffix());
  foreach $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      if (!&is_slots($generic)) {
        if (!&is_src_decl() && !&is_target_decl()) {
          &generate_generic_defn($generic, $is_inline, $col, $ns);
          &generate_generic_func_ptr_defn($generic, $is_inline, $col, $ns);
        }
        &generate_generic_func_defn($generic, $is_inline, $col, $ns);
      }
    }
  }
  $$scratch_str_ref .= $col . &labeled_src_str(undef, "va-generics-super-t" . '-' . &suffix());
  foreach $generic (sort method::compare @$generics) {
    if (&is_va($generic)) {
      if (!&is_slots($generic)) {
        my $copy = &deep_copy($generic);
        $$copy{'parameter-types'}[0][0] = 'super-t';
        if (!&is_src_decl() && !&is_target_decl()) {
          &generate_generic_defn($copy, $is_inline, $col, $ns);
          &generate_generic_func_ptr_defn($copy, $is_inline, $col, $ns);
        }
        &generate_generic_func_defn($copy, $is_inline, $col, $ns);
      }
    }
  }
  #$$scratch_str_ref .= "# endif // defined DKT-VA-GENERICS" . $nl;
  #if (!&is_slots($generic)) {
  &generate_va_generic_defns($generics, $is_inline = 0, $col, $ns);
  #}
  $$scratch_str_ref .= $col . &labeled_src_str(undef, "generics-object-t" . '-' . &suffix());
  foreach $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      if (!&is_slots($generic)) {
        if (!&is_src_decl() && !&is_target_decl()) {
          &generate_generic_defn($generic, $is_inline, $col, $ns);
          &generate_generic_func_ptr_defn($generic, $is_inline, $col, $ns);
        }
        &generate_generic_func_defn($generic, $is_inline, $col, $ns);
      }
    }
  }
  $$scratch_str_ref .= $col . &labeled_src_str(undef, "generics-super-t" . '-' . &suffix());
  foreach $generic (sort method::compare @$generics) {
    if (!&is_va($generic)) {
      if (!&is_slots($generic)) {
        my $copy = &deep_copy($generic);
        $$copy{'parameter-types'}[0][0] = 'super-t';
        if (!&is_src_decl() && !&is_target_decl()) {
          &generate_generic_defn($copy, $is_inline, $col, $ns);
          &generate_generic_func_ptr_defn($copy, $is_inline, $col, $ns);
        }
        &generate_generic_func_defn($copy, $is_inline, $col, $ns);
      }
    }
  }
}
sub linkage_unit::generate_signatures {
  my ($generics) = @_;
  my $col = '';
  my $scratch_str = "";
  $scratch_str .= &common::generate_signature_defns($generics, $col); # __signature::foobar(...)
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_signatures_seq {
  my ($generics) = @_;
  my $col = '';
  my $scratch_str = "";
  if (&is_src_defn() || &is_target_defn()) {
    my $is_inline;
    $scratch_str .= &generics::generate_signature_seq($generics, $is_inline = 0, $col);
  }
  return $scratch_str;
}
sub linkage_unit::generate_selectors {
  my ($generics) = @_;
  my $col = '';
  my $scratch_str = "";
  $scratch_str .= &common::generate_selector_defns($generics, $col); # __selector::foobar(...)
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_selectors_seq {
  my ($generics) = @_;
  my $col = '';
  my $scratch_str = "";
  if (&is_src_defn() || &is_target_defn()) {
    my $is_inline;
    $scratch_str .= &generics::generate_selector_seq($generics, $is_inline = 0, $col);
  }
  return $scratch_str;
}
sub linkage_unit::generate_generics {
  my ($scope, $col) = @_;
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  my ($is_inline, $ns);
  &generate_generic_defns($scope, $is_inline = 0, $col, $ns = 'dk');

  $$scratch_str_ref .=
    $nl .
    $col . "# if !defined DK-USE-MAKE-MACRO" . $nl .
    &generate_va_make_defn($scope, $is_inline = 1, &colin($col)) .
    $col . "# endif" . $nl;
  return $$scratch_str_ref;
}
sub generate_va_make_defn {
  my ($generics, $is_inline, $col) = @_;
  my $result = '';
  #$result .= $col . "// generate_va_make_defn()" . $nl;
  $result .= $col . "[[sentinel]] INLINE func make(object-t kls, ...) -> object-t";
  if (&is_src_decl() || &is_target_decl()) {
    $result .= ";" . $nl;
  } elsif (&is_target_defn()) {
    my $alloc_type_decl = "func (*alloc)(object-t) -> object-t"; ### should use method::type_decl
    my $init_type_decl =  "func (*_func_)(object-t, va-list-t) -> object-t"; ### should use method::type_decl

    $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $result .=
      $col . "static $alloc_type_decl = dk::alloc;" . $nl .
      $col . "static $init_type_decl = dk::va::init;" . $nl .
      $nl .
      $col . "object-t instance = alloc(kls);" . $nl .
      $nl .
      $col . "va-list-t args;" . $nl .
      $col . "va-start(args, kls);" . $nl .
      #$col . "DKT-VA-TRACE-BEFORE(SIGNATURE(va::init(object-t, va-list-t)), cast(method-t)_func_, instance, args);" . $nl .
      $col . "instance = _func_(instance, args); // dk::va::init(object-t, va-list-t)" . $nl .
      #$col . "DKT-VA-TRACE-AFTER( SIGNATURE(va::init(object-t, va-list-t)), cast(method-t)_func_, instance, args);" . $nl .
      $col . "va-end(args);" . $nl .
      $col . "return instance;" . $nl;
    $col = &colout($col);
    $result .= $col . "}" . $nl;
  }
  return $result;
}
## exists()  (does this key exist)
## defined() (is the value (for this key) non-undef)
sub dk_parse {
  my ($dk_path) = @_; # string.dk
  my $ast_path = &dakota::parse::ast_path_from_dk_path($dk_path);
  my $file = &dakota::util::scalar_from_file($ast_path);
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
    $$scratch_str_ref .= ' ' . &slots_decl($slots_scope) . ' {' . &ann(__FILE__, __LINE__) . $nl;
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
    if (defined $$slot_info{'expr'}) {
      $$scratch_str_ref .= $col . "$$slot_info{'type'} " . $pad . "$$slot_info{'name'} = $$slot_info{'expr'};" . $nl;
    } else {
      $$scratch_str_ref .= $col . "$$slot_info{'type'} " . $pad . "$$slot_info{'name'};" . $nl;
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
    $$scratch_str_ref .= 'enum' . " @{$$enum{'type'}}";
  } else {
    $$scratch_str_ref .= 'enum';
  }
  if ($$enum{'enum-base'}) {
    $$scratch_str_ref .= ' : ' . $$enum{'enum-base'};
  } else {
    $$scratch_str_ref .= ' : int-t';
  }
  $$scratch_str_ref .= " {" . &ann(__FILE__, __LINE__) . $nl;
  my $max_width = 0;
  foreach my $slot_info (@$slots_info) {
    my $width = length($$slot_info{'name'});
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $slot_info (@$slots_info) {
    if (defined $$slot_info{'expr'}) {
      my $width = length($$slot_info{'name'});
      my $pad = ' ' x ($max_width - $width);
      $$scratch_str_ref .= $col . "$$slot_info{'name'} = " . $pad . "$$slot_info{'expr'}," . $nl;
    } else {
      $$scratch_str_ref .= $col . "$$slot_info{'name'}," . $nl;
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '};';
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

    if (defined $$slot_info{'expr'}) {
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
  my $object_method_sig = &func::overloadsig($object_method_info, []);

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
    #$result .= $col . "// special-case: no generated unbox() for klass 'object' due to Koenig lookup" . $nl;
  } elsif ($klass_name eq 'klass') {
    $result .= $col . "klass $klass_name { [[unbox-attrs]] func unbox(object-t object) noexcept -> slots-t&";

    if (&is_src_decl() || &is_target_decl()) {
      $result .= "; }" . &ann(__FILE__, __LINE__) . " // special-case" . $nl;
    } elsif (&is_target_defn()) {
      $result .=
        " {" . &ann(__FILE__, __LINE__) . " // special-case" . $nl .
        $col . "  DEBUG-STMT(dkt-unbox-check(object, klass)); // optional" . $nl .
        $col . "  slots-t& s = *cast(slots-t*)(cast(uint8-t*)object + sizeof(object::slots-t));" . $nl .
        $col . "  return s;" . $nl .
        $col . "}}" . $nl;
    }
  } else {
    ### unbox() same for all types
    my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
    if ($is_klass_defn || (&has_exported_slots($klass_scope) && &has_slots_info($klass_scope))) {
      $result .= $col . "klass $klass_name { [[unbox-attrs]] func unbox(object-t object) noexcept -> slots-t&";
      if (&is_src_decl() || &is_target_decl()) {
        $result .= "; }" . &ann(__FILE__, __LINE__) . $nl; # general-case
      } elsif (&is_target_defn()) {
        $result .=
          " {" . &ann(__FILE__, __LINE__) . $nl .
          $col . "  DEBUG-STMT(dkt-unbox-check(object, klass)); // optional" . $nl .
          $col . "  slots-t& s = *cast(slots-t*)(cast(uint8-t*)object + klass::unbox(klass).offset);" . $nl .
          $col . "  return s;" . $nl .
          $col . "}}" . $nl;
      }
    }
  }
  return $result;
}
sub generate_klass_box {
  my ($klass_scope, $klass_path, $klass_name) = @_;
  my $result = '';
  my $col = '';

  if ('object' eq &ct($klass_path)) {
    ### box() non-array-type
    $result .= $col . "klass $klass_name { func box(slots-t* arg) -> object-t";

    if (&is_src_decl() || &is_target_decl()) {
      $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
    } elsif (&is_target_defn()) {
      $result .=
        " {" . &ann(__FILE__, __LINE__) . $nl .
        $col . "  return arg;" . $nl .
        $col . "}}" . $nl;
    }
  } else {
    if (&has_exported_slots($klass_scope)) {
      ### box()
      if (&is_array_type($$klass_scope{'slots'}{'type'})) {
        ### box() array-type
        $result .= $col . "klass $klass_name { func box(slots-t arg) -> object-t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "object-t result = make(klass);" . $nl .
            $col . "memcpy(unbox(result), arg, sizeof(slots-t)); // unfortunate" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}}" . $nl;
        }
        $result .= $col . "klass $klass_name { func box(slots-t* arg) -> object-t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "object-t result = box(*arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}}" . $nl;
        }
      } else { # !&is_array_type()
        ### box() non-array-type
        $result .= $col . "klass $klass_name { func box(slots-t* arg) -> object-t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          if ($$klass_scope{'init-supports-kw-slots?'}) {
            $result .=
              $col . "object-t result = make(klass, \#slots : *arg);" . $nl;
          } else {
            $result .=
              $col . "object-t result = make(klass);" . $nl .
              $col . "unbox(result) = *arg;" . $nl;
          }
          $result .= $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}}" . $nl;
        }
        $result .= $col . "klass $klass_name { func box(slots-t arg) -> object-t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "object-t result = $klass_name\::box(&arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}}" . $nl;
        }
      }
    }
  }
  if ((&is_src_decl() || &is_target_decl) && &has_exported_slots($klass_scope) && &has_slots_type($klass_scope)) {
    $result .= $col . "using $klass_name\::box;" . &ann(__FILE__, __LINE__) . $nl;
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
          if (&is_src_decl() || &is_target_decl()) {
            $result .= $col . "klass $klass_name { func construct($pairs_w_expr) -> slots-t; }" . &ann(__FILE__, __LINE__) . $nl;
          } elsif (&is_target_defn()) {
            $result .= $col . "klass $klass_name { func construct($pairs) -> slots-t {" . &ann(__FILE__, __LINE__) . $nl;
            $col = &colin($col);
            $result .=
              $col . "slots-t result = cast(slots-t){ $names };" . $nl .
              $col . "return result;" . $nl;
            $col = &colout($col);
            $result .= $col . "}}" . $nl;
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

  if (&is_src_decl() || &is_target_decl()) {
    #$$scratch_str_ref .= $col . "extern symbol-t __type__;" . $nl;
    $$scratch_str_ref .= $col . "$klass_type $klass_name { extern symbol-t __klass__; }" . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    #$$scratch_str_ref .= $col . "symbol-t __type__ = \$$klass_type;" . $nl;
    my $literal_symbol = &as_literal_symbol(&ct($klass_path));
    $$scratch_str_ref .= $col . "$klass_type $klass_name { symbol-t __klass__ = $literal_symbol; }" . &ann(__FILE__, __LINE__) . $nl;
  }

  if ('trait' eq $klass_type) {
    if (&is_src_decl() || &is_target_decl()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { func klass(object-t) -> object-t; }" . &ann(__FILE__, __LINE__) . $nl;
    } elsif (&is_target_defn()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { func klass(object-t self) -> object-t { return \$klass-with-trait(klass-of(self), __klass__); } }" . &ann(__FILE__, __LINE__) . $nl;
    }
  }
  if ('klass' eq $klass_type) {
    if (&is_src_decl() || &is_target_decl()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { extern object-t klass [[read-only]]; }" . &ann(__FILE__, __LINE__) . $nl;
    } elsif (&is_target_defn()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { object-t klass = nullptr; }" . &ann(__FILE__, __LINE__) . $nl;
    }
    if (!&is_target_defn()) {
      my $is_exported;
      if (exists $$klass_scope{'const'}) {
        foreach my $const (@{$$klass_scope{'const'}}) {
          $$scratch_str_ref .= $col . "$klass_type $klass_name { extern const $$const{'type'} $$const{'name'}; }" . &ann(__FILE__, __LINE__) . $nl;
        }
      }
    }
    my $object_method_defns = {};
    foreach $method (sort method::compare values %{$$klass_scope{'slots-methods'}}) {
      if (&is_src_defn() || &is_target_defn() || &is_exported($method)) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'parameter-types'}[0])) {
            my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
            #$$scratch_str_ref .= $col . "$klass_type $klass_name { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "REMOVE") . $nl;
            if (!&has_object_method_defn($klass_scope, $method)) {
              my $object_method = &convert_to_object_method($method);
              my $sig = &func::overloadsig($object_method, []);
              if (!$$object_method_defns{$sig}) {
                &generate_object_method_defn($method, $klass_path, $col, $klass_type, __LINE__);
              }
              $$object_method_defns{$sig} = 1;
            }
          }
        }
      } else {
        if (!&is_va($method)) {
          my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
          $$scratch_str_ref .= $col . "$klass_type $klass_name { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "DUPLICATE") . $nl;
          my $object_method = &convert_to_object_method($method);
          my $sig = &func::overloadsig($object_method, []);
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
      if (&is_src_defn() || &is_target_defn()) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'parameter-types'}[0])) {
            my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
            $$scratch_str_ref .= $col . "$klass_type $klass_name { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__) . $nl;
            if (!&has_object_method_defn($klass_scope, $method)) {
              my $object_method = &convert_to_object_method($method);
              my $sig = &func::overloadsig($object_method, []);
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
          #my $sig = &func::overloadsig($object_method, []);
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
    $$scratch_str_ref .= $col . "$klass_type $klass_name { initialize(object-t kls) -> void; }" . &ann(__FILE__, __LINE__) . $nl;
  }
  if (&is_decl() && $$klass_scope{'has-finalize'}) {
    $$scratch_str_ref .= $col . "$klass_type $klass_name { finalize(object-t kls) -> void; }" . &ann(__FILE__, __LINE__) . $nl;
  }
  if (&is_decl() && @$kw_args_methods) {
    #print STDERR Dumper($va_list_methods);
    &generate_kw_args_method_signature_decls($$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_decl() && defined $$klass_scope{'slots-methods'}) {
    #print STDERR Dumper($va_list_methods);
    &generate_slots_method_signature_decls($$klass_scope{'slots-methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_target() && !&is_decl() && defined $$klass_scope{'slots-methods'}) {
    &generate_slots_method_signature_defns($$klass_scope{'slots-methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_decl() && @$va_list_methods) { #rn0
    #print STDERR Dumper($va_list_methods);
    foreach $method (@$va_list_methods) {
      my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
      if (exists $$method{'keyword-types'}) {
        $$scratch_str_ref .= $col . "$klass_type $klass_name { namespace va { ${visibility}METHOD $$method_decl_ref }} /*kw-args*/" . &ann(__FILE__, __LINE__, "stmt1") . $nl;
      } else {
        $$scratch_str_ref .= $col . "$klass_type $klass_name { namespace va { ${visibility}METHOD $$method_decl_ref }} /*va*/" . &ann(__FILE__, __LINE__, "stmt1") . $nl;
      }
    }
  }
  if (@$va_list_methods) {
    foreach $method (@$va_list_methods) {
      if (1) {
        my $va_method = &dakota::util::deep_copy($method);
        #$$va_method{'inline?'} = 1;
        #if (&is_decl() || &is_same_file($klass_scope)) #rn1
        if (&is_same_src_file($klass_scope) || &is_decl()) { #rn1
          if (defined $$method{'keyword-types'}) {
            &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
            if (0 == @{$$va_method{'keyword-types'}}) {
              my $last = &dakota::util::remove_last($$va_method{'parameter-types'});
              die if 'va-list-t' ne &ct($last);
              my ($visibility, $method_decl_ref) = &func::decl($va_method, $klass_path);
              $$scratch_str_ref .= $col . "$klass_type $klass_name { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "stmt2") . $nl;
              &dakota::util::add_last($$va_method{'parameter-types'}, $last);
            }
          }
          else {
            &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
          }
        } else {
          &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, __LINE__);
        }
        if (&is_decl) {
          if (&is_same_src_file($klass_scope) || &is_target()) { #rn2
            if (defined $$method{'keyword-types'}) {
              if (0 != @{$$method{'keyword-types'}}) {
                my $other_method_decl = &kw_args_method::type_decl($method);

                #my $scope = &ct($klass_path);
                $other_method_decl =~ s|\(\*($id)\)| $1|;
                my $visibility = '';
                if (&is_exported($method)) {
                  $visibility = '[[export]] ';
                }
                if ($$method{'inline?'}) {
                  #$$scratch_str_ref .= 'INLINE ';
                }
                $$scratch_str_ref .= $col . "$klass_type $klass_name { " . $visibility . "METHOD $other_method_decl; }" . &ann(__FILE__, __LINE__, "stmt3") . $nl;
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
      if (&is_same_src_file($klass_scope) || &is_target()) { #rn3
        if (!&is_va($method)) {
          my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
          $$scratch_str_ref .= $col . "$klass_type $klass_name { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__, "DUPLICATE") . $nl;
        }
      }
    }
  }
}
sub generate_object_method_decl {
  my ($non_object_method, $klass_path, $col, $klass_type, $line) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $object_method = &convert_to_object_method($non_object_method);
  my ($visibility, $method_decl_ref) = &func::decl($object_method, $klass_path);
  $$scratch_str_ref .= $col . "$klass_type @$klass_path { ${visibility}METHOD $$method_decl_ref }" . &ann(__FILE__, $line) . $nl;
}
sub generate_object_method_defn {
  my ($non_object_method, $klass_path, $col, $klass_type, $line) = @_;
  my $method = &convert_to_object_method($non_object_method);
  my $new_arg_type = $$method{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'parameter-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  my $new_arg_list =  &arg_type::list_pair($new_arg_type, $new_arg_names);

  my $non_object_return_type = &arg::type($$non_object_method{'return-type'});
  my $return_type = &arg::type($$method{'return-type'});
  my $scratch_str_ref = &global_scratch_str_ref();
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = '[[export]] ';
  }
  my $method_name = &ct($$method{'name'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_path { " . $visibility . "METHOD $method_name($$new_arg_list) -> $return_type";

  my $new_unboxed_arg_names = &arg_type::names_unboxed($$non_object_method{'parameter-types'});
  my $new_unboxed_arg_names_list = &arg_type::list_names($new_unboxed_arg_names);

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= ";" . &ann(__FILE__, $line) . " }" . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . $nl;
    $col = &colin($col);

    if (defined $$method{'return-type'}) {
      if ($non_object_return_type ne $return_type) {
        $$scratch_str_ref .= $col . "$return_type result = box($method_name($$new_unboxed_arg_names_list));" . $nl;
      } else {
        $$scratch_str_ref .= $col . "$return_type result = $method_name($$new_unboxed_arg_names_list);" . $nl;
      }
    }
    if (defined $$method{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;" . $nl;
    } else {
      $$scratch_str_ref .= $col . "return;" . $nl;
    }
    $col = &colout($col);
    $$scratch_str_ref .= $col . "}}" . $nl;
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
sub typealias_slots_t {
  my ($klass_name) = @_;
  my $result;
  if ('object' eq $klass_name) {
    $result = "typealias $klass_name-t = $klass_name\::slots-t*; /*special-case*/"; # special-case
  } else {
    my $parts = [split(/::/, $klass_name)];
    if (1 < scalar @$parts) {
      my $basename = &dakota::util::remove_last($parts);
      my $inner_ns = join('::', @$parts);
      $result = "namespace $inner_ns { typealias $basename-t = $basename\::slots-t; }";
    } else {
      $result = "typealias $klass_name-t = $klass_name\::slots-t;";
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
    $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    if (&is_same_src_file($klass_scope)) {
      $$scratch_str_ref .= $col .        &typealias_slots_t($klass_name) . $nl;
    } else {
      $$scratch_str_ref .= $col . '//' . &typealias_slots_t($klass_name) . $nl;
    }
  } elsif (!&has_exported_slots($klass_scope) && &has_slots($klass_scope)) {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { ";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_scope{'slots'}, $is_exported = 0, $is_slots = 1);
      $$scratch_str_ref .= $col . " }" . $nl;
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:" . $nl;
    }
    $$scratch_str_ref .= $col . '//' . &typealias_slots_t($klass_name) . $nl;
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
sub generate_exported_slots_decls {
  my ($scope, $col, $klass_path, $klass_name, $klass_scope) = @_;
  if (!$klass_scope) {
    $klass_scope = &generics::klass_scope_from_klass_name($klass_name);
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  if ('object' eq "$klass_name") {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "//klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $col . &typealias_slots_t($klass_name) . &ann(__FILE__, __LINE__) . " // special-case" . $nl;
  } elsif (&has_exported_slots($klass_scope) && &has_slots_type($klass_scope)) {
    $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    my $excluded_types = { 'char16-t' => '__STDC_UTF_16__',
                           'char32-t' => '__STDC_UTF_32__',
                           'wchar-t'  => undef, # __WCHAR_MAX__, __WCHAR_TYPE__
                         };
    if (!exists $$excluded_types{"$klass_name-t"}) {
      $$scratch_str_ref .= $col . &typealias_slots_t($klass_name) . $nl;
    }
  } elsif (&has_exported_slots($klass_scope) || (&has_slots($klass_scope) && &is_same_file($klass_scope))) {
    if ('struct' eq $$klass_scope{'slots'}{'cat'} ||
        'union'  eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { " . &slots_decl($$klass_scope{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    } elsif ('enum' eq $$klass_scope{'slots'}{'cat'}) {
      $$scratch_str_ref .= $col . "klass $klass_name { ";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_scope{'slots'}, $is_exported = 1, $is_slots = 1);
      $$scratch_str_ref .= $col . " }" . $nl;
    } else {
      print STDERR &Dumper($$klass_scope{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $col . &typealias_slots_t($klass_name) . $nl;
  } else {
    #errdump($klass_name);
    #errdump($klass_scope);
    die __FILE__, ':', __LINE__, ": error: box klass \'$klass_name\' without slot or slots" . $nl;
  }
}
sub linkage_unit::generate_headers {
  my ($scope, $klass_names, $extra_header) = @_;
  my $result = '';

  if (&is_decl()) {
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
      $result .= "# include $header_name" . $nl;
    }
  }
  $result .= $extra_header;
  return $result;
}
sub is_same_file {
  my ($klass_scope) = @_;
  if ($gbl_src_file && $$klass_scope{'slots'} && $$klass_scope{'slots'}{'file'}) {
    return 1 if $gbl_src_file eq &canon_path($$klass_scope{'slots'}{'file'});
  }
  return 0;
}
sub is_same_src_file {
  my ($klass_scope) = @_;
  if ($gbl_src_file && $$klass_scope{'file'}) {
    return 1 if $gbl_src_file eq &canon_path($$klass_scope{'file'});
  }
  return 0;
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
  if (exists $$klass_scope{'slots'} && defined $$klass_scope{'slots'}) {
    return 1;
  }
  return 0;
}
sub has_exported_slots {
  my ($klass_scope) = @_;
  if (&has_slots($klass_scope)) {
    return &is_exported($$klass_scope{'slots'});
  }
  return 0;
}
sub has_methods {
  my ($klass_scope) = @_;
  if (exists $$klass_scope{'methods'} && 0 != keys %{$$klass_scope{'methods'}}) {
    return 1;
  }
  return 0;
}
sub has_exported_methods {
  my ($klass_scope) = @_;
  if (&has_methods($klass_scope)) {
    if (exists $$klass_scope{'behavior-exported?'} && defined $$klass_scope{'behavior-exported?'}) {
      return $$klass_scope{'behavior-exported?'};
    }
  }
  return 0;
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
                    print STDERR "    $type\n      $type_klass_name" . $nl;
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
          print STDERR "klass-name: $klass_name" . $nl;
        }
        if (&has_slots($klass_scope)) {
          if ($$klass_scope{'slots'}{'type'}) {
            if ($verbose) {
              print STDERR "  type:" . $nl;
            }
            my $type = $$klass_scope{'slots'}{'type'};
            my $type_klass_name;
            my $parts = {};
            &klass_part($type_aliases, $type, $parts);
            foreach $type_klass_name (keys %$parts) {
              if ($verbose) {
                print STDERR "    $type\n      $type_klass_name" . $nl;
              }
              if ($klass_name ne $type_klass_name) {
                $$depends{$klass_name}{$type_klass_name} = 1;
              }
            }
          } elsif ($$klass_scope{'slots'}{'info'}) {
            if ($verbose) {
              print STDERR "  info:" . $nl;
            }
            foreach my $slots_info (@{$$klass_scope{'slots'}{'info'}}) {
              my $types = [values %$slots_info];
              foreach my $type (@$types) {
                my $type_klass_name;
                my $parts = {};
                &klass_part($type_aliases, $type, $parts);
                foreach $type_klass_name (keys %$parts) {
                  if ($verbose) {
                    print STDERR "    $type\n      $type_klass_name" . $nl;
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
    &dakota::util::add_last($$ordered_klasses{'seq'}, $str);
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
  my ($scope, $ordered_klass_names) = @_;
  my $col = '';
  my $klass_path = [];
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_types_before($scope, $col, $klass_path, $ordered_klass_names);
  if (&is_decl()) {
    $$scratch_str_ref .=
      $nl .
      $col . "# include <dakota-finally.$hh_ext> // hackhack: should be before dakota.$hh_ext" . $nl .
      $col . "# include <dakota.$hh_ext>" . $nl .
      $col . "# include <dakota-log.$hh_ext>" . $nl;

    if (&is_target()) {
      $$scratch_str_ref .=
        $nl .
        $col . "# include <dakota-os.$hh_ext>" . $nl;
    }
    $$scratch_str_ref .= $nl;
  }
  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-slots" . '-' . &suffix());
  &linkage_unit::generate_klasses_types_after($scope, $col, $klass_path, $ordered_klass_names);

  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-klass" . '-' . &suffix());
  foreach my $klass_name (sort @$ordered_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass($scope, $col, $klass_path, $klass_name);
  }
  if (&is_decl()) {
    $$scratch_str_ref .=
      $nl .
      $col . "# include <dakota-of.$hh_ext> // klass-of(), superklass-of(), name-of()" . $nl .
      $nl;
  }
  return $$scratch_str_ref;
}
sub linkage_unit::generate_klasses_types_before {
  my ($scope, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
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
            $$scratch_str_ref .= $col . " }" . $nl;
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
          $$scratch_str_ref .= $col . " }" . $nl;
        }
      } elsif (&is_src_defn() || &is_target_defn()) {
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
            $$scratch_str_ref .= $col . " }" . $nl;
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
            $$scratch_str_ref .= $col . " }" . $nl;
          }
        }
      }
    }
  }
  $$scratch_str_ref .= $nl;
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
  return "(*)($$arg_type_list) -> $return_type_str";
}
sub method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &arg_type::list_types($$method{'parameter-types'});
  my $name = &dakota::util::last($$method{'name'});
  return "(*$name)($$arg_type_list) -> $return_type";
}
sub kw_args_method::type {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'parameter-types'}, $$method{'keyword-types'});
  return "(*)($$arg_type_list) -> $return_type";
}
sub kw_args_method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'parameter-types'}, $$method{'keyword-types'});
  my $name = &dakota::util::last($$method{'name'});
  return "(*$name)($$arg_type_list) -> $return_type";
}
sub slots_signature_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num =  0;
  my $max_width = 0;
  my $return_type = 'const signature-t*';
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
      my $generic_name = &ct($$method{'name'});
      if (&is_va($method)) {
        $result .= $col . "(cast(dkt-signature-func-t)cast(func $method_type)" . $pad . "__method-signature::va::$generic_name)()," . $nl;
      } else {
        $result .= $col . "(cast(dkt-signature-func-t)cast(func $method_type)" . $pad . "__method-signature::$generic_name)()," . $nl;
      }
      my $method_name;

      if ($$method{'alias'}) {
        $method_name = &ct($$method{'alias'});
      } else {
        $method_name = &ct($$method{'name'});
      }
    }
    $method_num++;
  }
  $result .= $col . "nullptr" . $nl;
  return $result;
}
sub split_methods_by_addr {
  my ($methods) = @_;
  my $sorted_methods = [sort method::compare @$methods];
  my $methods_w_addr = [];
  my $methods_wo_addr = [];
  foreach my $method (@$sorted_methods) {
    if (!$$method{'alias'}) {
      if ($$method{'defined?'} || $$method{'generated?'}) {
        &add_last($methods_w_addr, $method);
      } else {
        &add_last($methods_wo_addr, $method);
      }
    }
  }
  return ( $methods_w_addr, $methods_wo_addr );
}
sub signature_body_common {
  my ($methods, $col) = @_;
  my $result = '';

  foreach my $method (@$methods) {
    if (!$$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = &ct($$method{'name'});
      my $in = &ident_comment($generic_name);
      if (&is_va($method)) {
        $result .= $col . "SIGNATURE(va::$generic_name($$new_arg_type_list))," . $in . $nl;
      } else {
        $result .= $col . "SIGNATURE($generic_name($$new_arg_type_list))," . $in . $nl;
      }
    }
  }
  return $result;
}
sub signature_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my ($methods_w_addr, $methods_wo_addr) = &split_methods_by_addr($sorted_methods);
  $result .= &signature_body_common($methods_w_addr, $col);
  if (scalar @$methods_w_addr && @$methods_wo_addr) {
    $result .= $nl;
  }
  $result .= &signature_body_common($methods_wo_addr, $col);
  $result .= $col . "nullptr" . $nl;
  return $result;
}
sub address_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $max_width = 0;
  foreach my $method (@$sorted_methods) {
    if (!$$method{'alias'}) {
      if ($$method{'defined?'} || $$method{'generated?'}) {
        my $method_type = &method::type($method);
        my $width = length("cast(func $method_type)");
        if ($width > $max_width) {
          $max_width = $width;
        }
      } else {
        # skip because its declared but not defined and should not be considered for padding
      }
    }
  }
  my ($methods_w_addr, $methods_wo_addr) = &split_methods_by_addr($sorted_methods);
  foreach my $method (@$methods_w_addr) {
    if (!$$method{'alias'}) {
      my $method_type = &method::type($method);
      my $width = length("cast(func $method_type)");
      my $pad = ' ' x ($max_width - $width);
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = &ct($$method{'name'});
      my $in = &ident_comment($generic_name);

      if (&is_va($method)) {
        $result .= $col . "cast(method-t)cast(func $method_type)" . $pad . "va::$generic_name," . $in . $nl;
      } else {
        $result .= $col . "cast(method-t)cast(func $method_type)" . $pad . "$generic_name," . $in . $nl;
      }
    }
  }
  if (scalar @$methods_w_addr && @$methods_wo_addr) {
    $result .= $nl;
  }
  foreach my $method (@$methods_wo_addr) {
    if (!$$method{'alias'}) {
      my $generic_name = &ct($$method{'name'});
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $return_type = &arg::type($$method{'return-type'});
      $result .=   $col . 'cast(method-t)dkt-null-method, ' . "/* $generic_name($$new_arg_type_list) -> $return_type */" . $nl;
    }
  }
  $result .= $col . "nullptr" . $nl;
  return $result;
}
sub alias_body {
  my ($klass_name, $methods, $col) = @_;
  my $sorted_methods = [sort method::compare values %$methods];
  my $result = '';
  my $method_num =  0;
  foreach my $method (@$sorted_methods) {
    if ($$method{'alias'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'parameter-types'});
      my $generic_name = &ct($$method{'name'});
      my $alias_name = &ct($$method{'alias'});
      if (&is_va($method)) {
        $result .= $col . "{ .alias-signature = SIGNATURE(va::$alias_name($$new_arg_type_list)), .method-signature = SIGNATURE(va::$generic_name($$new_arg_type_list)) }," . $nl;
      } else {
        $result .= $col . "{ .alias-signature = SIGNATURE($alias_name($$new_arg_type_list)), .method-signature = SIGNATURE($generic_name($$new_arg_type_list)) }," . $nl;
      }
    }
    $method_num++;
  }
  $result .= $col . "{ .alias-signature = nullptr, .method-signature = nullptr }" . $nl;
  return $result;
}
sub export_pair {
  my ($symbol, $element) = @_;
  my $name = &ct($$element{'name'});
  my $type0 = &ct($$element{'parameter-types'}[0]);
  $type0 = ''; # hackhack
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
sub dk_generate_cc_footer_klass {
  my ($klass_scope, $klass_name, $col, $klass_type, $symbols) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_cc_footer_klass()" . $nl;

  my $token_registry = {};

  my $slot_type;
  my $slot_name;

  my $method_aliases = &klass::method_aliases($klass_scope);
  my $va_list_methods = &klass::va_list_methods($klass_scope);
  my $kw_args_methods = &klass::kw_args_methods($klass_scope);

  #my $num_va_methods = @$va_list_methods;

  #if (@$va_list_methods)
  #{
  #$$scratch_str_ref .= $col . "namespace va {" . $nl;
  #$col = &colin($col);
  ###
  if (@$va_list_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const signature-t* const __va-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " // redundant" . $nl;

    my $sorted_va_methods = [sort method::compare @$va_list_methods];

    $col = &colin($col);
    foreach my $va_method (@$sorted_va_methods) {
      if ($$va_method{'defined?'} || $$va_method{'alias'}) {
        my $new_arg_type_list = &arg_type::list_types($$va_method{'parameter-types'});
        my $generic_name = &ct($$va_method{'name'});
        my $in = &ident_comment($generic_name);
        $$scratch_str_ref .= $col . "SIGNATURE(va::$generic_name($$new_arg_type_list))," . $in . $nl;
        my $method_name;

        if ($$va_method{'alias'}) {
          $method_name = &ct($$va_method{'alias'});
        } else {
          $method_name = &ct($$va_method{'name'});
        }

        my $old_parameter_types = $$va_method{'parameter-types'};
        $$va_method{'parameter-types'} = &arg_type::var_args($$va_method{'parameter-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'parameter-types'} = $old_parameter_types;

        my $return_type = &arg::type($$va_method{'return-type'});
        my $va_method_name = $method_name;
        #$$scratch_str_ref .= $col . "(var-args-method-t)(($method_type)$va_method_name)," . $nl;
      }
    }
    $$scratch_str_ref .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  ###
  ###
  if (@$va_list_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static var-args-method-t __var-args-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    ### todo: this looks like it might merge with address_body(). see die below
    my $sorted_va_methods = [sort method::compare @$va_list_methods];

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

        my $generic_name = &ct($$va_method{'name'});
        my $method_name;

        if ($$va_method{'alias'}) {
          $method_name = &ct($$va_method{'alias'});
        } else {
          $method_name = &ct($$va_method{'name'});
        }
        die if (!$$va_method{'defined?'} && !$$va_method{'alias'} && !$$va_method{'generated?'});

        my $old_parameter_types = $$va_method{'parameter-types'};
        $$va_method{'parameter-types'} = &arg_type::var_args($$va_method{'parameter-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'parameter-types'} = $old_parameter_types;

        my $return_type = &arg::type($$va_method{'return-type'});
        my $va_method_name = $method_name;
        $$scratch_str_ref .= $col . "cast(var-args-method-t)cast(func $method_type)" . $pad . "$va_method_name," . $nl;
      }
    }
    $$scratch_str_ref .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  ###
  #$col = &colout($col);
  #$$scratch_str_ref .= $col . "}" . $nl;
  #}
  ###
  if (@$kw_args_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const signature-t* const __kw-args-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    #$$scratch_str_ref .= "\#if 0" . $nl;
    foreach my $kw_args_method (@$kw_args_methods) {
      $kw_args_method = &dakota::util::deep_copy($kw_args_method);
      my $list_types = &arg_type::list_types($$kw_args_method{'parameter-types'});
      my $method_name = &ct($$kw_args_method{'name'});
      my $in = &ident_comment($method_name);
     #my $kw_list_types = &method::kw_list_types($kw_args_method);
      $$scratch_str_ref .= $col . "KW-ARGS-METHOD-SIGNATURE(va::$method_name($$list_types))," . $in . $nl;
    }
    #$$scratch_str_ref .= "\#endif" . $nl;
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  if (values %{$$klass_scope{'methods'} ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const __method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &signature_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  if (values %{$$klass_scope{'methods'} ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-t __method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &address_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  my $num_method_aliases = scalar(@$method_aliases);
  if ($num_method_aliases) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-alias-t __method-aliases[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &alias_body($klass_name, $$klass_scope{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  my $exported_methods =     &exported_methods($klass_scope);
  my $exported_slots_methods = &exported_slots_methods($klass_scope);

  if (values %{$exported_methods ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const __exported-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &signature_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}" . $nl .
      $col . "$klass_type @$klass_name { static method-t __exported-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &address_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}" . $nl;
  }
  if (values %{$exported_slots_methods ||= []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const __exported-slots-method-signatures[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &slots_signature_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}" . $nl .
      $col . "$klass_type @$klass_name { static method-t __exported-slots-method-addresses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl .
      $col . &address_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}" . $nl;
  }
  ###
  ###
  ###
  #$$scratch_str_ref .= $nl;

  my $num_traits = @{( $$klass_scope{'traits'} ||= [] )}; # how to get around 'strict'
  if ($num_traits > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __traits[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    my $trait_num = 0;
    for ($trait_num = 0; $trait_num < $num_traits; $trait_num++) {
      my $path = "$$klass_scope{'traits'}[$trait_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $num_requires = @{( $$klass_scope{'requires'} ||= [] )}; # how to get around 'strict'
  if ($num_requires > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __requires[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    my $require_num = 0;
    for ($require_num = 0; $require_num < $num_requires; $require_num++) {
      my $path = "$$klass_scope{'requires'}[$require_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $num_provides = @{( $$klass_scope{'provides'} ||= [] )}; # how to get around 'strict'
  if ($num_provides > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t __provides[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    my $provide_num = 0;
    for ($provide_num = 0; $provide_num < $num_provides; $provide_num++) {
      my $path = "$$klass_scope{'provides'}[$provide_num]";
      $$scratch_str_ref .= $col . "$path\::__klass__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
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
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t const __imported-klasses[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    while (my ($key, $val) = each(%{$$klass_scope{'imported-klasses'}})) {
      $$scratch_str_ref .= $col . "$key\::__klass__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
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
          $$tbl{'#expr'} = "($$slot_info{'expr'})";
          $$tbl{'#expr-str'} = "\"$$slot_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }" . $nl;
        &dakota::util::add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_target_runtime_info_seq($root_name, $seq, $col, __LINE__) . "}" . $nl;
    } else {
      my $seq = [];
      my $prop_num = 0;
      foreach my $slot_info (@{$$klass_scope{'slots'}{'info'}}) {
        my $tbl = {};
        $$tbl{'#name'} = "\#$$slot_info{'name'}";

        if ('struct' eq $$klass_scope{'slots'}{'cat'}) {
          $$tbl{'#offset'} = "offsetof(slots-t, $$slot_info{'name'})";
        }
        my $slot_name_ref = 'slots-t::' . $$slot_info{'name'};
        $$tbl{'#size'} = 'sizeof(' . $slot_name_ref . ')';
        $$tbl{'#type'} = &as_literal_symbol($$slot_info{'type'});
        $$tbl{'#typeid'} = 'INTERNED-DEMANGLED-TYPEID-NAME(' . $slot_name_ref . ')';

        if (defined $$slot_info{'expr'}) {
          $$tbl{'#expr'} = "($$slot_info{'expr'})";
          $$tbl{'#expr-str'} = "\"$$slot_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }" . $nl;
        &dakota::util::add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_target_runtime_info_seq($root_name, $seq, $col, __LINE__) . " }" . $nl;
    }
  }
  if (&has_enum_info($klass_scope)) {
    my $num = 0;
    foreach my $enum (@{$$klass_scope{'enum'}}) {
      $$scratch_str_ref .= $col . "$klass_type @$klass_name { static enum-info-t __enum-info-$num\[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
      $col = &colin($col);

      my $slots_info = $$enum{'info'};
      foreach my $slot_info (@$slots_info) {
        my $name = $$slot_info{'name'};
        if (defined $$slot_info{'expr'}) {
          my $expr = $$slot_info{'expr'};
          $$scratch_str_ref .= $col . "{ .name = \#$name, .expr = $expr }," . $nl;
        } else {
          $$scratch_str_ref .= $col . "{ .name = \#$name, .expr = nullptr }," . $nl;
        }
      }
      $$scratch_str_ref .= $col . "{ .name = nullptr, .expr = nullptr }" . $nl;
      $col = &colout($col);
      $$scratch_str_ref .= $col . "};}" . $nl;

      $num++;
    }
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static named-enum-info-t __enum-info[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    $num = 0;
    foreach my $enum (@{$$klass_scope{'enum'}}) {
      if ($$enum{'type'}) {
        my $type = &ct($$enum{'type'});
        $$scratch_str_ref .= $col . "{ .name = \"$type\", .info = __enum-info-$num }," . $nl;
      } else {
        $$scratch_str_ref .= $col . "{ .name = nullptr, .info = __enum-info-$num }," . $nl;
      }
      $num++;
    }
    $$scratch_str_ref .= $col . "{ .name = nullptr, .info = nullptr }" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  if (&has_const_info($klass_scope)) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const-info-t __const-info[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);

    foreach my $const (@{$$klass_scope{'const'}}) {
      my $value = join(' ', @{$$const{'rhs'}});
      $value =~ s/"/\\"/g;
      $$scratch_str_ref .= $col . "{ .name = \#$$const{'name'}, .type = \"$$const{'type'}\", .value = \"$value\" }," . $nl;
    }
    $$scratch_str_ref .= $col . "{ .name = nullptr, .type = nullptr, .value = nullptr }" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $symbol = &ct($klass_name);
  $$tbbl{'#name'} = '__klass__';
  $$tbbl{'#type'} = "\#$klass_type";

  if (&has_slots_type($klass_scope)) {
    my $slots_type_ident = &dk_mangle($$klass_scope{'slots'}{'type'});
    $$tbbl{'#slots-type'} = &as_literal_symbol($$klass_scope{'slots'}{'type'});
    my $tp = 'slots-t';
   #$$tbbl{'#slots-typeid'} = 'dk-intern-free(dkt::demangle(typeid(' . $tp . ').name()))';
    $$tbbl{'#slots-typeid'} = 'INTERNED-DEMANGLED-TYPEID-NAME(' . $tp . ')';
  } elsif (&has_slots_info($klass_scope)) {
    my $cat = $$klass_scope{'slots'}{'cat'};
    $$tbbl{'#cat'} = "\#$cat";
    $$tbbl{'#slots-info'} = '__slots-info';
  }
  if ($$klass_scope{'slots'}{'enum-base'}) {
    $$tbbl{'#enum-base'} = "\#$$klass_scope{'slots'}{'enum-base'}";
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
    $$tbbl{'#method-addresses'} =  '__method-addresses';
  }
  if ($num_method_aliases) {
    $$tbbl{'#method-aliases'} = '&__method-aliases';
  }
  if (values %{$exported_methods ||= []}) {
    $$tbbl{'#exported-method-signatures'} = '__exported-method-signatures';
    $$tbbl{'#exported-method-addresses'} =  '__exported-method-addresses';
  }
  if (values %{$exported_slots_methods ||= []}) {
    $$tbbl{'#exported-slots-method-signatures'} = '__exported-slots-method-signatures';
    $$tbbl{'#exported-slots-method-addresses'} =  '__exported-slots-method-addresses';
  }
  if (@$va_list_methods) {
    $$tbbl{'#va-method-signatures'} =       '__va-method-signatures';
    $$tbbl{'#var-args-method-addresses'} =  '__var-args-method-addresses';
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
    $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl('__klass-props', $tbbl, $col, $symbols, __LINE__) .
    $col . " }" . $nl;
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
  my $method_name = &ct($$method{'name'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
 #my $kw_list_types = &method::kw_list_types($method);
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { namespace va { func $method_name($$list_types) -> const signature-t*; }}} /*kw-args-method-signature*/ " . &ann(__FILE__, __LINE__) . $nl;
}
sub generate_kw_args_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { namespace va { func $method_name($$list_types) -> const signature-t* { /*kw-args-method-signature*/ " . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $kw_list_types = &method::kw_list_types($method);
 #$kw_list_types = &remove_extra_whitespace($kw_list_types);
  if (1) { # optional?
    my $defs = [];
    foreach my $keyword_types (@{$$method{'keyword-types'}}) {
      if (defined $$keyword_types{'default'}) {
        my $def = $$keyword_types{'default'};
        $def =~ s/"/\\"/g;
        &add_last($defs, $def);
      }
    }
    my $kw_arg_default_placeholder = $$kw_args_placeholders{'default'};
    foreach my $def (@$defs) {
      if (1) {
        $def =~ s/dk::/\$/g;
      }
      my $count = $kw_list_types =~ s/$kw_arg_default_placeholder/ $def/; # extra whitespace
      die if 1 != $count;
    }
  }
  my $padlen = length($col);
  $padlen += length("static const signature-t result = { ");
  my $kw_arg_list = "static const signature-t result = { .name =            \"$method_name\"," . $nl .
    (' ' x $padlen) . ".parameter-types = \"$kw_list_types\"," . $nl .
    (' ' x $padlen) . ".return-type =     \"$return_type\" };" . $nl;
  $$scratch_str_ref .=
    $col . "$kw_arg_list" . $nl .
    $col . "return &result;" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}}" . $nl;
}
sub generate_slots_method_signature_decl {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { func $method_name($$list_types) -> const signature-t*; }} /*slots-method-signature*/ " . &ann(__FILE__, __LINE__) . $nl;
}
sub generate_slots_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { func $method_name($$list_types) -> const signature-t* { /*slots-method-signature*/ " . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $method_list_types = &method::list_types($method);
  $method_list_types = &remove_extra_whitespace($method_list_types);
  my $padlen = length($col);
  $padlen += length("static const signature-t result = { ");
  my $arg_list =    "static const signature-t result = { .name =            \"$method_name\"," . $nl .
    (' ' x $padlen) . ".parameter-types = \"$method_list_types\"," . $nl .
    (' ' x $padlen) . ".return-type =     \"$return_type\" };" . $nl;
  $$scratch_str_ref .=
    $col . "$arg_list" . $nl .
    $col . "return &result;" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}" . $nl;
}
sub generate_kw_args_method_defns {
  my ($slots, $methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if ($$method{'keyword-types'}) {
      &generate_kw_args_method_defn($slots, $method, $klass_name, $col, $klass_type);
    }
  }
}
sub generate_kw_args_method_defn {
  my ($slots, $method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_kw_args_method_defn()" . $nl;

  my $qualified_klass_name = &ct($klass_name);

  #&path::add_last($klass_name, 'va');
  my $new_arg_type = $$method{'parameter-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'parameter-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  &dakota::util::_replace_first($new_arg_names, 'self');
  &dakota::util::_replace_last($new_arg_names, '_args_');
  my $new_arg_list =  &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$method{'return-type'});
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = '[[export]] ';
  }
  my $func_spec = '';
  #if ($$method{'inline?'})
  #{
  #    $func_spec = 'INLINE ';
  #}
  my $method_name = &ct($$method{'name'});
  my $method_type_decl;
  my $list_types = &arg_type::list_types($$method{'parameter-types'});
  my $list_names = &arg_type::list_names($$method{'parameter-types'});

  $$scratch_str_ref .=
    "$klass_type @$klass_name { namespace va { " . $visibility . $func_spec . "METHOD $method_name($$new_arg_list) -> $return_type { /*kw-args*/ " . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);

  $$scratch_str_ref .=
    $col . "static const signature-t* __method-signature__ = KW-ARGS-METHOD-SIGNATURE(va::$method_name($$list_types)); USE(__method-signature__);" . $nl;

  $$method{'name'} = [ '_func_' ];
  my $func_name = &ct($$method{'name'});

  #$$scratch_str_ref .=
  #  $col . "static const signature-t* __method-signature__ = KW-ARGS-METHOD-SIGNATURE(va::$method_name($$list_types)); USE(__method-signature__);" . $nl;

  my $arg_names = &dakota::util::deep_copy(&arg_type::names(&dakota::util::deep_copy($$method{'parameter-types'})));
  my $arg_names_list = &arg_type::list_names($arg_names);

  if (scalar @{$$method{'keyword-types'}}) {
    #my $param = &dakota::util::remove_last($$method{'parameter-types'}); # remove intptr-t type
    $method_type_decl = &kw_args_method::type_decl($method);
    #&dakota::util::add_last($$method{'parameter-types'}, $param);
  } else {
    my $param1 = &dakota::util::remove_last($$method{'parameter-types'}); # remove va-list-t type
    # should test $param1
    #my $param2 = &dakota::util::remove_last($$method{'parameter-types'}); # remove intptr-t type
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
      $kw_arg_type =~ s/\[\s*\]$/*/; # to change object-t[] objects to object-t* objects
      $$scratch_str_ref .= "$delim$kw_arg_type $kw_arg_name \{};";
      $delim = ' ';
    }
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "struct {";
    my $initializer = '';
    $delim = '';
    foreach my $kw_arg (@{$$method{'keyword-types'}}) {
      my $kw_arg_name = $$kw_arg{'name'};
      $$scratch_str_ref .= " boole-t $kw_arg_name;";
      $initializer .= "${delim}false";
      $delim = ', ';
    }
    $$scratch_str_ref .= " } _state_ = { $initializer };" . $nl;
  }
  #$$scratch_str_ref .= $col . "if (nullptr != $$new_arg_names[-1]) {" . $nl;
  #$col = &colin($col);
  $$scratch_str_ref .=
    $col . "keyword-t* _keyword_;" . $nl .
    $col . "while (nullptr != (_keyword_ = va-arg(_args_, decltype(_keyword_)))) {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  $$scratch_str_ref .= $col . "switch (_keyword_->hash) { // hash is a constexpr. its compile-time evaluated." . $nl;
  $col = &colin($col);

  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    my $kw_arg_type = &arg::type($$kw_arg{'type'});
    $$scratch_str_ref .= $col . "case \#$kw_arg_name: // dk-hash() is a constexpr. its compile-time evaluated." . $nl;
    #$$scratch_str_ref .= $col . "{" . $nl;
    $col = &colin($col);
    # should do this for other types (char=>int, float=>double, ... ???
    $$scratch_str_ref .=
      $col . "assert(_keyword_->symbol == \#$kw_arg_name);" . $nl;
    my $promoted_type;
    if ($$gbl_compiler_default_argument_promotions{$kw_arg_type}) {
      $promoted_type = $$gbl_compiler_default_argument_promotions{$kw_arg_type};
    } elsif ($$slots{'type'} && $$gbl_compiler_default_argument_promotions{$$slots{'type'}}) {
      $promoted_type = $$gbl_compiler_default_argument_promotions{$$slots{'type'}};
    }
    if ($promoted_type) {
      $$scratch_str_ref .=
        $col . "$kw_arg_name = cast($kw_arg_type)va-arg($$new_arg_names[-1], $promoted_type); // special-case: default argument promotions" . $nl;
    } else {
      $$scratch_str_ref .=
        $col . "$kw_arg_name = va-arg($$new_arg_names[-1], decltype($kw_arg_name));" . $nl;
    }

    $$scratch_str_ref .=
      $col . "_state_.$kw_arg_name = true;" . $nl .
      $col . "break;" . $nl;
    $col = &colout($col);
    #$$scratch_str_ref .= $col . "}" . $nl;
  }
  $$scratch_str_ref .= $col . "default:" . $nl;
  #$$scratch_str_ref .= $col . "{" . $nl;
  $col = &colin($col);
  $$scratch_str_ref .=
    $col . "throw make(no-such-keyword-exception::klass," . $nl .
    $col . "           \#object $colon    self," . $nl .
    $col . "           \#signature $colon __method-signature__," . $nl .
    $col . "           \#keyword $colon   _keyword_->symbol);" . $nl;
  $col = &colout($col);
  #$$scratch_str_ref .= $col . "}" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}" . $nl;

  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_type =  &arg::type($$kw_arg{'type'});
    my $kw_arg_name =    $$kw_arg{'name'};
    $$scratch_str_ref .= $col . "unless (_state_.$kw_arg_name)" . $nl;
    $col = &colin($col);
    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default = $$kw_arg{'default'};
      if ($kw_arg_type =~ /\[\]$/ && $kw_arg_default =~ /^\{/) {
        $$scratch_str_ref .= $col . "$kw_arg_name = cast($kw_arg_type)$kw_arg_default;" . $nl;
      } else {
        $$scratch_str_ref .= $col . "$kw_arg_name = $kw_arg_default;" . $nl;
      }
    } else {
      $$scratch_str_ref .=
        $col . "throw make(missing-keyword-exception::klass," . $nl .
        $col . "           \#object $colon    self," . $nl .
        $col . "           \#signature $colon __method-signature__," . $nl .
        $col . "           \#keyword $colon   _keyword_->symbol);" . $nl;
    }
    $col = &colout($col);
  }
  my $delim = '';
  #my $last_arg_name = &dakota::util::remove_last($new_arg_names); # remove name associated with intptr-t type
  my $args = '';

  for (my $i = 0; $i < @$new_arg_names - 1; $i++) {
    $args .= "$delim$$new_arg_names[$i]";
    $delim = ', ';
  }
  #&dakota::util::add_last($new_arg_names, $last_arg_name); # add name associated with intptr-t type
  foreach my $kw_arg (@{$$method{'keyword-types'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    $args .= ", $kw_arg_name";
  }
  $$scratch_str_ref .= $col . "static func $method_type_decl = $qualified_klass_name\::$method_name; /*qualqual*/" . $nl;
  if ($$method{'return-type'}) {
    $$scratch_str_ref .=
      $col . "$return_type _result_ = $func_name($args);" . $nl .
      $col . "return _result_;" . $nl;
  } else {
    $$scratch_str_ref .=
      $col . "$func_name($args);" . $nl .
      $col . "return;" . $nl;
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}" . $nl;
  #&path::remove_last($klass_name);
}
sub dk_generate_cc_footer {
  my ($scope) = @_;
  my $stack = [];
  my $col = '';
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  &dk_generate_kw_args_method_defns($scope, $stack, 'trait', $col);
  &dk_generate_kw_args_method_defns($scope, $stack, 'klass', $col);

  if (&is_target_defn()) {
    my $num_klasses = scalar @$global_klass_defns;
    if (0 == $num_klasses) {
      $$scratch_str_ref .= $nl;
      $$scratch_str_ref .= $col . "static named-info-t* klass-defns = nullptr;" . $nl;
    } else {
      $$scratch_str_ref .= &generate_target_runtime_info_seq('klass-defns', [sort @$global_klass_defns], $col, __LINE__);
    }
    if (0 == keys %{$$scope{'interposers'}}) {
      $$scratch_str_ref .= $nl;
      $$scratch_str_ref .= $col . "static property-t* interposers = nullptr;" . &ann(__FILE__, __LINE__) . $nl;
    } else {
      #print STDERR Dumper $$scope{'interposers'};
      my $interposers = &many_1_to_1_from_1_to_many($$scope{'interposers'});
      #print STDERR Dumper $interposers;

      $$scratch_str_ref .= $col . "static property-t interposers[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
      $col = &colin($col);
      my ($key, $val);
      my $num_klasses = scalar keys %$interposers;
      foreach $key (sort keys %$interposers) {
        $val = $$interposers{$key};
        $$scratch_str_ref .= $col . "{ .key = $key\::__klass__, .element = cast(intptr-t)$val\::__klass__ }," . $nl;
      }
      $$scratch_str_ref .= $col . "{ .key = nullptr, .element = cast(intptr-t)nullptr }" . $nl;
      $col = &colout($col);
      $$scratch_str_ref .= $col . "};" . $nl;
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
      if (&is_target_defn()) {
        &dk_generate_cc_footer_klass($klass_scope, $stack, $col, $klass_type, $$scope{'symbols'});
      } else {
        &generate_kw_args_method_signature_defns($$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
        &generate_kw_args_method_defns($$klass_scope{'slots'}, $$klass_scope{'methods'}, [ $klass_name ], $col, $klass_type);
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
sub add_symbol_to_ident_symbol {
  my ($file_symbols, $symbols, $symbol) = @_;
  if (defined $symbol) {
    $symbol = &as_literal_symbol_interior($symbol);
    my $literal_symbol = &as_literal_symbol($symbol);
    my $ident_symbol = &dk_mangle($symbol);
    $$file_symbols{$literal_symbol} = $ident_symbol;
    $$symbols{$literal_symbol} = $ident_symbol;
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
  #print "ann-interval: " . $ann_interval . $nl; 
  #print "num-ann-lns: " . $num_lns . ' / ' . $ann_interval . $nl;
  #print "num-ann-lns: " . $num_ann_lns . $nl;
  #print "adjusted-ann-interval: " . $adjusted_ann_interval . $nl;
  $result = 1 if !(($ln + 1) % $adjusted_ann_interval);
  return $result;
}
sub linkage_unit::generate_symbols {
  my ($file, $symbols) = @_;
  my $col = '';

  while (my ($symbol, $symbol_seq) = each(%$symbols)) {
    my $ident_symbol = &dk_mangle_seq($symbol_seq);
    $$symbols{$symbol} = $ident_symbol;
  }
  foreach my $symbol (keys %{$$file{'symbols'}}) {
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
      my $klass_typealias = "$symbol-t";

      if (!exists $$symbols{$klass_typealias}) {
        &add_symbol_to_ident_symbol($$file{'symbols'}, $symbols, $klass_typealias);
      }
    }
  }
  my $symbol_keys = [sort symbol::compare keys %$symbols];
  my $scratch_str = "";
  my $max_width = 0;
  foreach my $symbol (@$symbol_keys) {
    $symbol = &as_literal_symbol_interior($symbol);
    my $ident = &dk_mangle($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  $scratch_str .= $col . 'namespace __symbol {' . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $num_lns = @$symbol_keys;
  while (my ($ln, $symbol) = each @$symbol_keys) {
    $symbol =~ s/^#//;
    my $ident = &dk_mangle($symbol);
    my $width = length($ident);
    $ident =~ s/(\w)_(\w)/$1-$2/g;
    my $pad = ' ' x ($max_width - $width);
    if (&is_src_decl() || &is_target_decl()) {
      $scratch_str .= $col . "extern symbol-t $ident;" . ' /* ' . &as_literal_symbol($symbol) . ' */' . $nl;
    } elsif (&is_target_defn()) {
      $symbol =~ s|"|\\"|g;
      if (&should_ann($ln, $num_lns)) {
        $scratch_str .= $col . "symbol-t $ident = " . $pad . "dk-intern(\"$symbol\");" . &ann(__FILE__, __LINE__) . $nl;
      } else {
        $scratch_str .= $col . "symbol-t $ident = " . $pad . "dk-intern(\"$symbol\");" . $nl;
      }
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  $scratch_str .= $nl;
  return $scratch_str;
}
sub linkage_unit::generate_hashes {
  my ($file) = @_;
  my $col = '';

  my ($symbol, $symbol_seq);
  my $symbol_keys = [sort symbol::compare keys %{$$file{'keywords'}}];
  my $max_width = 0;
  foreach $symbol (@$symbol_keys) {
    my $ident = &dk_mangle($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  my $scratch_str = "";
  if (&is_target_defn()) {
    $scratch_str .= $col . 'namespace __hash {' . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    my $num_lns = @$symbol_keys;
    while (my ($ln, $symbol) = each @$symbol_keys) {
      $symbol =~ s/^#//;
      my $ident = &dk_mangle($symbol);
      my $width = length($ident);
      $ident =~ s/(\w)_(\w)/$1-$2/g;
      my $pad = ' ' x ($max_width - $width);
      if (&should_ann($ln, $num_lns)) {
        $scratch_str .= $col . "constexpr hash-t $ident = " . $pad . "dk-hash(\"$symbol\");" . &ann(__FILE__, __LINE__) . $nl;
      } else {
        $scratch_str .= $col . "constexpr hash-t $ident = " . $pad . "dk-hash(\"$symbol\");" . $nl;
      }
    }
    $col = &colout($col);
    $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
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
  my ($file) = @_;
  my $col = '';

  my ($symbol, $symbol_seq);
  my $symbol_keys = [sort symbol::compare keys %{$$file{'keywords'}}];
  my $max_width = 0;
  foreach $symbol (@$symbol_keys) {
    $symbol =~ s/^#//;
    my $ident = &dk_mangle($symbol);
    my $width = length($ident);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  my $scratch_str = "";

  $scratch_str .= $col . 'namespace __keyword {' . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $num_lns = @$symbol_keys;
  while (my ($ln, $symbol) = each @$symbol_keys) {
    $symbol =~ s/^#//;
    my $ident = &dk_mangle($symbol);
    my $width = length($ident);
    $ident =~ s/(\w)_(\w)/$1-$2/g;
    my $pad = ' ' x ($max_width - $width);
    if (defined $ident) {
      if (&is_decl()) {
        $scratch_str .= $col . "extern keyword-t $ident;" . $nl;
      } else {
        my $in = &ident_comment($symbol);
        # keyword-defn
        if (&should_ann($ln, $num_lns)) {
          $scratch_str .= $col . "keyword-t $ident = " . $pad . "{ dk-hash(\"$symbol\"), " . $pad . "#$symbol };" . $in . &ann(__FILE__, __LINE__) . $nl;
        } else {
          $scratch_str .= $col . "keyword-t $ident = " . $pad . "{ dk-hash(\"$symbol\"), " . $pad . "#$symbol };" . $in . $nl;
        }
      }
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_strs {
  my ($file) = @_;
  my $scratch_str = "";
  my $col = '';
  $scratch_str .= $col . "namespace __literal::__str {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  foreach my $str (sort keys %{$$file{'literal-strs'}}) {
    my $str_ident = &dk_mangle($str);
    if (&is_decl()) {
      $scratch_str .= $col . "extern object-t $str_ident; // \"$str\"" . $nl;
    } else {
      $scratch_str .= $col . "object-t $str_ident = nullptr; // \"$str\"" . $nl;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . "}" . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_strs_seq {
  my ($file) = @_;
  my $scratch_str = "";
  my $col = '';
  if (0 == scalar keys %{$$file{'literal-strs'}}) {
    $scratch_str .= $col . "//static str-t const __str-literals[] = { nullptr };" . &ann(__FILE__, __LINE__) . " // ro-data" . $nl;
    $scratch_str .= $col . "//static object-t* __str-ptrs[] = { nullptr };" . &ann(__FILE__, __LINE__) . " // rw-data" . $nl;
  } else {
    $scratch_str .= $col . "static str-t const __str-literals[] = {" . &ann(__FILE__, __LINE__) . " // ro-data" . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$file{'literal-strs'}}) {
      $scratch_str .= $col . "\"$str\"," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static symbol-t __str-names[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$file{'literal-strs'}}) {
      my $ident = &dk_mangle($str);
      $scratch_str .= $col . "__symbol::$ident," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static assoc-node-t __str-ptrs[] = {" . &ann(__FILE__, __LINE__) . " // rw-data" . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$file{'literal-strs'}}) {
      my $str_ident = &dk_mangle($str);
      $scratch_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)&__literal::__str::$str_ident }," . $nl;
    }
    $scratch_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)nullptr }" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub linkage_unit::generate_ints {
  my ($file) = @_;
  my $scratch_str = "";
  my $col = '';
  $scratch_str .= $col . "namespace __literal::__int {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  foreach my $int (sort keys %{$$file{'literal-ints'}}) {
    my $int_ident = &dk_mangle($int);
    if (&is_decl()) {
      $scratch_str .= $col . "extern object-t $int_ident;" . $nl;
    } else {
      $scratch_str .= $col . "object-t $int_ident = nullptr;" . $nl;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . "}" . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_ints_seq {
  my ($file) = @_;
  my $scratch_str = "";
  my $col = '';
  if (0 == scalar keys %{$$file{'literal-ints'}}) {
    $scratch_str .= $col . "//static intptr-t const __int-literals[] = { 0 };" . &ann(__FILE__, __LINE__) . " // ro-data" . $nl;
    $scratch_str .= $col . "//static object-t* __int-ptrs[] = { nullptr };" . &ann(__FILE__, __LINE__) . " // rw-data" . $nl;
  } else {
    $scratch_str .= $col . "static intptr-t const __int-literals[] = {" . &ann(__FILE__, __LINE__) . " // ro-data" . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$file{'literal-ints'}}) {
      $scratch_str .= $col . "$int," . $nl;
    }
    $scratch_str .= $col . "0 // nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static symbol-t __int-names[] = {" . &ann(__FILE__, __LINE__) . " //ro-data" . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$file{'literal-ints'}}) {
      my $ident = &dk_mangle($int);
      $scratch_str .= $col . "__symbol::$ident," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static assoc-node-t __int-ptrs[] = {" . &ann(__FILE__, __LINE__) . " // rw-data" . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$file{'literal-ints'}}) {
      my $int_ident = &dk_mangle($int);
      $scratch_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)&__literal::__int::$int_ident }," . $nl;
    }
    $scratch_str .= $col . "{ .next = nullptr, .element = cast(intptr-t)nullptr }" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub generate_target_runtime_property_tbl {
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
      $result .= &generate_target_runtime_info("$name-$num", $element, $col, $symbols, $line);
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
  $result .= "static property-t $name\[] = {" . &ann(__FILE__, $line) . " //ro-data" . $nl;
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
      my $literal_symbol = &as_literal_symbol($1);
      if ($$symbols{$literal_symbol}) {
        $element = $literal_symbol;
      } else {
        $element = "dk-intern($element)";
      }
    }
    my $in1 = &ident_comment($key, 1);
    my $in2 = &ident_comment($element, 1);
    $result .= $col . "{ .key = $key, " . $pad . ".element = cast(intptr-t)$element }," . $in1 . $in2 . $nl;
  }
  $col = &colout($col);
  $result .= $col . "};";
  return $result;
}
sub generate_target_runtime_info {
  my ($name, $tbl, $col, $symbols, $line) = @_;
  my $result = &generate_target_runtime_property_tbl("$name-props", $tbl, $col, $symbols, $line);
  $result .= $nl;
  $result .= $col . "static named-info-t $name = { .next = nullptr, .count = countof($name-props), .elements = $name-props };" . &ann(__FILE__, $line) . $nl;
  return $result;
}
sub generate_target_runtime_info_seq {
  my ($name, $seq, $col, $line) = @_;
  my $result = '';

  $result .= $col . "static named-info-t $name\[] = {" . &ann(__FILE__, $line) . " //rw-data (.next)" . $nl;
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
    $result .= $col . "{ .next = nullptr, .count = countof($element), " . $pad . ".elements = $element }," . $nl;
  }
  $result .= $col . "{ .next = nullptr, .count = 0, .elements = nullptr }" . $nl;
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
  my ($file, $path_name, $project_ast) = @_;
  my ($dir, $file_basename) = &split_path($file);
  my $filestr = &dakota::util::filestr_from_file($file);
  my $output = $path_name =~ s/\.dk$/\.$cc_ext/r;
  $output =~ s|^\./||;
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output
  }
  if (&is_debug()) {
    print "    creating $output" . &pann(__FILE__, __LINE__) . $nl; # user-dk-cc
  }
  my $remove;

  if ($ENV{'DK_NO_LINE'}) {
    &write_to_file_converted_strings("$output", [ $filestr ], $remove = 1, $project_ast);
  } else {
    my $num = 1;
    if ($ENV{'DK_ABS_PATH'}) {
      my $cwd = &getcwd();
      &write_to_file_converted_strings("$output", [ "# line $num \"$cwd/$file_basename\"" . $nl, $filestr ], $remove = 1, $project_ast);
    } else {
      &write_to_file_converted_strings("$output", [ "# line $num \"$file_basename\"" . $nl, $filestr ], $remove = 1, $project_ast);
    }
  }
}
sub start {
  my ($argv) = @_;
  foreach my $in_path (@$argv) {
    my $filestr = &dakota::util::filestr_from_file($in_path);
    my $path;
    my $remove;
    my $project_ast;
    &write_to_file_converted_strings($path = undef, [ $filestr ], $remove = undef, $project_ast = undef);
  }
}
unless (caller) {
  &start(\@ARGV);
}
1;
