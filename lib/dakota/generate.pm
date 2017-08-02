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

package dakota::generate;

use strict;
use warnings;
use sort 'stable';

my $should_check_type_traits = 1;
my $should_write_pre_output = 1;
my $gbl_ann_interval = 30;

my $emacs_cxx_mode_file_variables =    '-*- mode: c++ -*-';
my $emacs_dakota_mode_file_variables = '-*- mode: c++; mode: dakota -*-'; # fallback to c++ mode if dakota mode is not found

my $gbl_prefix;
my $gbl_compiler;
my $build_dir;
my $h_ext;
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
  use dakota::parse;
  use dakota::rewrite;
  use dakota::util;
  $gbl_compiler = &do_json("$gbl_prefix/lib/dakota/compiler-command-line.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/compiler-command-line.json\") failed: $!\n";
  my $platform = &do_json("$gbl_prefix/lib/dakota/platform.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/platform.json\") failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $h_ext = &var($gbl_compiler, 'h_ext', undef);
  $cc_ext = &var($gbl_compiler, 'cc_ext', undef);
};
my $use_new_macro_system = 0;

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
                 dk_generate_cc
                 empty_klass_defns
                 func::overloadsig
                 generate_src_decl
                 generate_src_defn
                 generate_target_decl
                 generate_target_defn
                 global_scratch_str_ref
                 set_global_scratch_str_ref
                 should_use_include
              );

my $colon = ':'; # key/item delim only
my $kw_arg_placeholders = &kw_arg_placeholders();
my ($id,  $mid,  $bid,  $tid,
    $rid, $rmid, $rbid, $rtid) = &ident_regex();

my $global_should_echo = 0;
my $global_scratch_str_ref;
#my $global_src_cc_str;

my $seq_super_t =   ['super-t']; # special (used in eq compare)
my $seq_ellipsis =  ['...'];
my $seq_object_t =  ['object-t'];
my $seq_va_list_t = ['va-list-t'];
my $object_t =  'object-t';
my $super_t =   'super-t';
my $keyword_t = 'keyword-t';
my $va_list_t = 'va-list-t';
my $global_klass_defns = [];

my $plural_from_singular = { 'klass', => 'klasses', 'trait' => 'traits' };

# not used. left over (converted) from old code gen model
sub src_path {
  my ($name, $ext) = @_;
  $build_dir = &build_dir();
  if ($ENV{'DK_ABS_PATH'}) {
    my $cwd = &getcwd();
    return "$cwd/$build_dir/$name.$ext";
  } else {
    return "$build_dir/$name.$ext";
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
sub extra_dakota_headers {
  my ($name) = @_;
  my $result = '';
  if (&is_decl()) {
    if (&is_target()) {
      $result .=
        "# include <unistd.h>" . $nl; # hardcoded-by-rnielsen
    }
    $result .=
      $nl .
      "# include <dakota.$h_ext>" . $nl .
      "# include <dakota-log.$h_ext> // optional" . $nl;
    if (&is_target()) {
      $result .=
        "# include <dakota-os.$h_ext>" . $nl;
    }
  } elsif (&is_target_defn()) { # generated target h file
    $result .=
      "# include \"$name.$h_ext\"" . $nl;
  } else {
    $result .=
      "bug-in-code-gen" . $nl;
  }
  return $result;
}
sub write_to_file_strings {
  my ($path, $strings) = @_;
  my $filestr = '';
  foreach my $string (@$strings) {
    $filestr .= $string;
  }
  &filestr_to_file($filestr, $path);
}
my $gbl_macros;
sub write_to_file_converted_strings {
  my ($path, $strings, $remove, $target_inputs_ast) = @_;
  if ($use_new_macro_system) {
    if (!defined $gbl_macros) {
      if ($ENV{'DK_MACROS_PATH'}) {
        $gbl_macros = &do_json($ENV{'DK_MACROS_PATH'}) or die "&do_json(\"$ENV{'DK_MACROS_PATH'}\") failed: $!\n";
      } elsif ($gbl_prefix) {
        $gbl_macros = &do_json("$gbl_prefix/lib/dakota/macros.json") or die "&do_json(\"$gbl_prefix/lib/dakota/macros.json\") failed: $!\n";
      } else {
        die;
      }
    }
  }
  my $filestr = '';

  foreach my $string (@$strings) {
    $filestr .= $string;
  }
  my $sst = &sst::make($filestr, ">$path"); # costly (< 1/4 of total)
  my $kw_arg_generics = $$target_inputs_ast{'kw-arg-generics'};
  if ($use_new_macro_system) {
    &dakota::macro_system::macros_expand($sst, $gbl_macros, $kw_arg_generics);
  }
  my $converted_string = &sst_fragment::filestr($$sst{'tokens'});
  &convert_dk_to_cc(\$converted_string, $kw_arg_generics, $remove); # costly (< 3/4 of total)
  my $should_echo;
  if (!&is_silent()) {
    $should_echo = 1 if $path =~ /target\.($h_ext|$cc_ext)$/;
  }
  # swap "# line 1" followed by "// -*- mode:" so the emacs mode line is first
  $converted_string =~ s=^(\s*#\s+line)\s+1(\s+.*?\n)(\s*//\s+-\*-\s+mode:.*?\n)=$3$1 2$2=s;
  &filestr_to_file($converted_string, $path, $should_echo);
}
sub is_silent {
  my $root_cmd = &root_cmd();
  return $$root_cmd{'opts'}{'silent'};
}
sub generate_src_decl {
  my ($path, $file_ast, $target_inputs_ast, $target_h_path) = @_;
  #print "generate_src_decl($path, ...)" . $nl;
  &set_src_decl($path);
  return &generate_src($path, $file_ast, $target_inputs_ast, $target_h_path);
}
sub generate_src_defn {
  my ($path, $file_ast, $target_inputs_ast, $target_h_path) = @_;
  #print "generate_src_defn($path, ...)" . $nl;
  &set_src_defn($path);
  return &generate_src($path, $file_ast, $target_inputs_ast, $target_h_path);
}
my $im_suffix_for_suffix = {
  $cc_ext => "$cc_ext.dkt",
  $h_ext => "$h_ext.dkt",
  'inc'   => 'inc.dkt',
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
sub add_include_fors {
  my ($ast, $include_fors) = @_;
  if (!$$ast{'include-fors'}) {
    $$ast{'include-fors'} = {};
  }
  while (my ($type, $includes) = each(%$include_fors)) {
    foreach my $include (keys %$includes) {
      $$ast{'include-fors'}{$type}{$include} = 1;
    }
  }
}
sub generate_src {
  my ($path, $file_ast, $target_inputs_ast, $target_h_path) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  $dir = '.' if !$dir;
  my $src_h_path = "$name.$h_ext";
  my $inc_path = $name . '.inc';
  my ($generics, $symbols) = &generics::parse($file_ast);
  my $suffix = &suffix();
  my $output = &canon_path("$dir/$name.$suffix");
  my $pre_output = &pre_output_path_from_any_path($output);
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output;
  }
  if ($$target_inputs_ast{'include-fors'}) {
    &add_include_fors($file_ast, $$target_inputs_ast{'include-fors'}); # BUGBUG
  }
  my $str;
  my $strings;
  if (&is_src_decl()) {
    return undef if !$ENV{'DK_SRC_UNIQUE_HEADER'};
    $str = &generate_decl_defn($file_ast, $generics, $symbols, $dir, $name, $suffix);
    $strings = [ undef,
                 '# pragma once' . $nl,
                 $str ];
  } else {
    $str =
      "# if !defined DK_SRC_UNIQUE_HEADER || 0 == DK_SRC_UNIQUE_HEADER" . $nl .
      "  # include \"$target_h_path\"" . &ann(__FILE__, __LINE__) . $nl .
      "# else" . $nl .
      "  # include \"$src_h_path\"" . &ann(__FILE__, __LINE__) . $nl .
      "# endif" . $nl .
      $nl .
      "# include \"$inc_path\"" . &ann(__FILE__, __LINE__) . $nl . # user-code (converted from dk to inc)
      $nl .
      &dk_generate_cc_footer($file_ast);
    $strings = [ undef,
                 $str ];
  }
  if ($should_write_pre_output) {
    $$strings[0] = '// ' . $emacs_dakota_mode_file_variables . $nl;
    &write_to_file_strings($pre_output, $strings);
    if (!$ENV{'DK_NO_LINE'}) {
      splice @$strings, 1, 0, "# line 2 \"$pre_output\"" . &ann(__FILE__, __LINE__) . $nl;
    }
  }
  $$strings[0] = '// ' . $emacs_cxx_mode_file_variables . $nl;
  my $remove;
  &write_to_file_converted_strings($output, $strings, $remove = undef, $target_inputs_ast);
  return $output;
} # sub generate_src
sub generate_target_decl {
  my ($path, $target_srcs_ast, $target_inputs_ast, $is_exe) = @_;
  #print "generate_target_decl($path, ...)" . $nl;
  &set_target_decl($path);
  if ($is_exe) {
    &set_exe_target($path);
  }
  return &generate_target($path, $target_srcs_ast, $target_inputs_ast);
}
sub generate_target_defn {
  my ($path, $target_srcs_ast, $target_inputs_ast, $is_exe) = @_;
  #print "generate_target_defn($path, ...)" . $nl;
  &set_target_defn($path);
  if ($is_exe) {
    &set_exe_target($path);
  }
  return &generate_target($path, $target_srcs_ast, $target_inputs_ast);
}
sub generate_target {
  my ($path, $target_srcs_ast, $target_inputs_ast) = @_;
  my ($dir, $name, $ext) = &split_path($path, $id);
  $dir = '.' if !$dir;
  my ($generics, $symbols) = &generics::parse($target_srcs_ast);
  my $suffix = &suffix();
  my $output = &canon_path("$dir/$name.$suffix");
  my $start_time;
  my $end_time;
  if (&is_debug()) {
    $start_time = time;
    print "  creating $output" . &pann(__FILE__, __LINE__) . $nl;
  }
  my $output_runtime;
  if (&is_target_defn()) {
    $output_runtime = "$dir/$name.inc";
    my $pre_output_runtime = &pre_output_path_from_any_path($output_runtime);
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output_runtime = $ENV{'DKT_DIR'} . '/' . $output_runtime;
    }
    my $str = &generate_target_runtime($target_srcs_ast, $generics);
    my $strings = [ undef,
                    $str ];
    if ($should_write_pre_output) {
      $$strings[0] = '// ' . $emacs_dakota_mode_file_variables . $nl;
      &write_to_file_strings($pre_output_runtime, $strings);
      if (!$ENV{'DK_NO_LINE'}) {
        splice @$strings, 1, 0, "# line 2 \"$pre_output_runtime\"" . &ann(__FILE__, __LINE__) . $nl;
      }
    }
    $$strings[0] = '// ' . $emacs_cxx_mode_file_variables . $nl;
    my $remove;
    &write_to_file_converted_strings($output_runtime, $strings, $remove = undef, $target_inputs_ast);
  }
  if (1) {
    my $pre_output = &pre_output_path_from_any_path($output);
    if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
      $output = $ENV{'DKT_DIR'} . '/' . $output;
    }
    if ($$target_inputs_ast{'include-fors'}) {
      &add_include_fors($target_srcs_ast, $$target_inputs_ast{'include-fors'}); # BUGBUG
    }
    my $str = &generate_decl_defn($target_srcs_ast, $generics, $symbols, $dir, $name, $suffix); # costly (> 1/8 of total)
    my $strings;
    if (&is_decl()) {
      $strings = [ undef,
                   '# pragma once' . $nl,
                   $str ];
    } else {
      $strings = [ undef,
                   $str ];
    }
    if ($output_runtime) {
      my $output_runtime_name = $output_runtime =~ s|^.*?([^/]+)$|$1|r;
      &add_last($strings, "# include \"$output_runtime_name\"" . &ann(__FILE__, __LINE__) . $nl);
    }
    if ($should_write_pre_output) {
      $$strings[0] = '// ' . $emacs_dakota_mode_file_variables . $nl;
      &write_to_file_strings($pre_output, $strings);
      if (!$ENV{'DK_NO_LINE'}) {
        splice @$strings, 1, 0, "# line 2 \"$pre_output\"" . &ann(__FILE__, __LINE__) . $nl;
      }
    }
    $$strings[0] = '// ' . $emacs_cxx_mode_file_variables . $nl;
    my $remove;
    &write_to_file_converted_strings($output, $strings, $remove = undef, $target_inputs_ast);
  }
  if (&is_debug()) {
    $end_time = time;
    my $elapsed_time = $end_time - $start_time;
    print "  creating $output ... done ($elapsed_time secs)" . &pann(__FILE__, __LINE__) . $nl;
  }
  return $output;
} # sub generate_target
sub desuffix {
  my ($str) = @_;
  $str =~ s/-($h_ext|$cc_ext)$//;
  return $str;
}
sub labeled_src_str {
  my ($tbl, $key) = @_;
  my $str = "/**--" . &desuffix($key) . '--**/' . $nl;
  if ($tbl) {
    $str .= $$tbl{$key};
    if (!exists $$tbl{$key}) {
      die "NO SUCH KEY $key";
    }
  }
  return $str;
}
sub add_labeled_src {
  my ($result, $label, $src) = @_;
  if (!$$result{'--labels'}) { $$result{'--labels'} = []; }
  &add_last($$result{'--labels'}, $label);
  $$result{$label} = $src;
}
sub generate_klass_funcs_and_write_to_file_converted {
  my ($ast, $ordered_klass_names, $output) = @_;
  my $col = '';
  my $strings = [ undef,
                  &linkage_unit::generate_klasses_funcs($ast, $ordered_klass_names) ];
  if ($should_write_pre_output) {
    my $pre_output = &pre_output_path_from_any_path($output);
    $$strings[0] = '// ' . $emacs_dakota_mode_file_variables . $nl;
    &write_to_file_strings($pre_output, $strings);
    if (!$ENV{'DK_NO_LINE'}) {
      splice @$strings, 1, 0, "# line 2 \"$pre_output\"" . &ann(__FILE__, __LINE__) . $nl;
    }
  }
  $$strings[0] = '// ' . $emacs_cxx_mode_file_variables . $nl;
  &write_to_file_converted_strings($output, $strings);
}
sub generate_generics_and_write_to_file_converted {
  my ($generics, $output) = @_;
  my $col = '';
  my $strings = [ undef,
                  &linkage_unit::generate_signatures($generics),
                  &linkage_unit::generate_selectors($generics, $col),
                  &linkage_unit::generate_generics($generics, $col) ];
  if ($should_write_pre_output) {
    my $pre_output = &pre_output_path_from_any_path($output);
    $$strings[0] = '// ' . $emacs_dakota_mode_file_variables . $nl;
    &write_to_file_strings($pre_output, $strings);
    if (!$ENV{'DK_NO_LINE'}) {
      splice @$strings, 1, 0, "# line 2 \"$pre_output\"" . &ann(__FILE__, __LINE__) . $nl;
    }
  }
  $$strings[0] = '// ' . $emacs_cxx_mode_file_variables . $nl;
  &write_to_file_converted_strings($output, $strings);
}
sub generate_decl_defn {
  my ($ast, $generics, $symbols, $dir, $name, $suffix) = @_;
  $dir = '.' if !$dir;
  my $result = {};
  my $extra_dakota_headers = &extra_dakota_headers($name);
  my $ordered_klass_names = &order_klasses($ast);

  &add_labeled_src($result, "headers-$suffix",  &linkage_unit::generate_headers( $ast, $ordered_klass_names, $extra_dakota_headers));
  &add_labeled_src($result, "symbols-$suffix",  &linkage_unit::generate_symbols( $ast, $symbols));
  &add_labeled_src($result, "klasses-$suffix",  &linkage_unit::generate_klasses( $ast, $ordered_klass_names));
  &add_labeled_src($result, "keywords-$suffix", &linkage_unit::generate_keywords($ast));
  &add_labeled_src($result, "strs-$suffix",     &linkage_unit::generate_strs(    $ast));
  &add_labeled_src($result, "ints-$suffix",     &linkage_unit::generate_ints(    $ast));
  my $col = '';

  my $klass_func_defns_path = "$name-klass-func-defns.inc";
  my $klass_func_decls_path = "$name-klass-func-decls.inc";

  my $target_klass_func_defns_path = &dakota::dakota::target_klass_func_defns_path();
  my $target_klass_func_decls_path = &dakota::dakota::target_klass_func_decls_path();

  if (&is_src_decl()) {
    &generate_klass_funcs_and_write_to_file_converted($ast, $ordered_klass_names, "$dir/$klass_func_decls_path");
    &add_labeled_src($result, "klass-funcs-$suffix",
                     "# if !defined DK_INLINE_KLASS_FUNCS || 0 == DK_INLINE_KLASS_FUNCS" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$klass_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# else" . $nl .
                     "  # define INLINE inline" . $nl .
                     "  # include \"$target_klass_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "  # include \"$target_klass_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  } elsif (&is_target_decl()) {
    &generate_klass_funcs_and_write_to_file_converted($ast, $ordered_klass_names, "$dir/$klass_func_decls_path");
    &add_labeled_src($result, "klass-funcs-$suffix",
                     "# if !defined DK_INLINE_KLASS_FUNCS || 0 == DK_INLINE_KLASS_FUNCS" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$klass_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# else" . $nl .
                     "  # define INLINE inline" . $nl .
                     "  # include \"$klass_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "  # include \"$klass_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  } elsif (&is_target_defn()) {
    &generate_klass_funcs_and_write_to_file_converted($ast, $ordered_klass_names, "$dir/$klass_func_defns_path");
    &add_labeled_src($result, "klass-funcs-$suffix",
                     "# if !defined DK_INLINE_KLASS_FUNCS || 0 == DK_INLINE_KLASS_FUNCS" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$klass_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  }
  my $generic_func_defns_path = "$name-generic-func-defns.inc";
  my $generic_func_decls_path = "$name-generic-func-decls.inc";

  my $target_generic_func_defns_path = &dakota::dakota::target_generic_func_defns_path();
  my $target_generic_func_decls_path = &dakota::dakota::target_generic_func_decls_path();

  if (&is_src_decl()) {
    &generate_generics_and_write_to_file_converted($generics, "$dir/$generic_func_decls_path");
    &add_labeled_src($result, "generic-funcs-$suffix",
                     "# if !defined DK_INLINE_GENERIC_FUNCS || 0 == DK_INLINE_GENERIC_FUNCS" . $nl .
                     "  # define STATIC static" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$generic_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# else" . $nl .
                     "  # define STATIC" . $nl .
                     "  # define INLINE inline" . $nl .
                     "  # include \"$target_generic_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "  # include \"$target_generic_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  } elsif (&is_target_decl()) {
    &generate_generics_and_write_to_file_converted($generics, "$dir/$generic_func_decls_path");
    &add_labeled_src($result, "generic-funcs-$suffix",
                     "# if !defined DK_INLINE_GENERIC_FUNCS || 0 == DK_INLINE_GENERIC_FUNCS" . $nl .
                     "  # define STATIC static" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$generic_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# else" . $nl .
                     "  # define STATIC" . $nl .
                     "  # define INLINE inline" . $nl .
                     "  # include \"$generic_func_decls_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "  # include \"$generic_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  } elsif (&is_target_defn()) {
    &generate_generics_and_write_to_file_converted($generics, "$dir/$generic_func_defns_path");
    &add_labeled_src($result, "generic-funcs-$suffix",
                     "# if !defined DK_INLINE_GENERIC_FUNCS || 0 == DK_INLINE_GENERIC_FUNCS" . $nl .
                     "  # define STATIC static" . $nl .
                     "  # define INLINE" . $nl .
                     "  # include \"$generic_func_defns_path\"" . &ann(__FILE__, __LINE__) . $nl .
                     "# endif" . $nl);
  }
  my $str =
    &labeled_src_str($result, "headers-$suffix") .
    &labeled_src_str($result, "symbols-$suffix") .
    &labeled_src_str($result, "klasses-$suffix");

  $str .=
    &labeled_src_str($result, "keywords-$suffix") .
    &labeled_src_str($result, "strs-$suffix") .
    &labeled_src_str($result, "ints-$suffix");

  if (&is_decl()) {
    $str .=
      $nl .
      "# if (OUT_OF_LINE_REF_COUNTING == 0)" . $nl .
      "  # include <dakota-object-defn.inc> // object-t" . $nl .
      "  # include <dakota-weak-object-defn.inc> // weak-object-t" . $nl .
      "# endif" . $nl .
      "# include <dakota-of.inc> // klass-of(), superklass-of(), name-of()" . $nl .
      $nl;
  }
  $str .=
    &labeled_src_str($result, "klass-funcs-$suffix") .
    &labeled_src_str($result, "generic-funcs-$suffix");

  return $str;
} # generate_decl_defn
sub generate_target_runtime {
  my ($target_srcs_ast, $generics) = @_;
  my $symbols_from_header = {};
  if ($$target_srcs_ast{'include-fors'}) {
    while (my ($symbol, $headers) = each (%{$$target_srcs_ast{'include-fors'}})) {
      foreach my $header (sort keys %$headers) {
        if (!defined $$symbols_from_header{$header}) {
          $$symbols_from_header{$header} = {}
        }
        $$symbols_from_header{$header}{$symbol} = undef;
      }
    }
  }
  my $target_cc_str = '';
  my $col = '';
  $target_cc_str .= $col . "static const str-t[] include-fors = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  foreach my $header (sort keys %$symbols_from_header) {
    $target_cc_str .= $col . "\"$header\",";
    foreach my $type (sort keys %{$$symbols_from_header{$header}}) {
      $target_cc_str .= $col . "\"$type\",";
    }
    $target_cc_str .= $col . "nullptr," . $nl;
  }
  $target_cc_str .= $col . "nullptr" . $nl;
  $col = &colout($col);
  $target_cc_str .= $col . "};" . $nl;

  my $keys_count = keys %{$$target_srcs_ast{'klasses'}};
  if (0 == $keys_count) {
    $target_cc_str .= $col . "static const symbol-t* imported-klass-names = nullptr;" . $nl;
    $target_cc_str .= $col . "static assoc-node-t*   imported-klass-ptrs =  nullptr;" . $nl;
  } else {
    $target_cc_str .= $col . "static symbol-t[] imported-klass-names = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    my $num_klasses = scalar keys %{$$target_srcs_ast{'klasses'}};
    foreach my $klass_name (sort keys %{$$target_srcs_ast{'klasses'}}) {
      $target_cc_str .= $col . "$klass_name\::__name__," . $nl;
    }
    $target_cc_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $target_cc_str .= $col . "};" . $nl;
    ###
    $target_cc_str .= $col . "static assoc-node-t[] imported-klass-ptrs = { //rw-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $num_klasses = scalar keys %{$$target_srcs_ast{'klasses'}};
    foreach my $klass_name (sort keys %{$$target_srcs_ast{'klasses'}}) {
      $target_cc_str .= $col . "{ .next = nullptr, .item = cast(intptr-t)&$klass_name\::_klass_ }, /// &object-t" . $nl;
    }
    $target_cc_str .= $col . "{ .next = nullptr, .item = cast(intptr-t)nullptr }" . $nl;
    $col = &colout($col);
    $target_cc_str .= $col . "};" . $nl;
    $target_cc_str .= &linkage_unit::generate_target_runtime_selectors_seq( $generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_signatures_seq($generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_generic_func_ptrs_seq($generics);
    $target_cc_str .= &linkage_unit::generate_target_runtime_strs_seq($target_srcs_ast);
    $target_cc_str .= &linkage_unit::generate_target_runtime_ints_seq($target_srcs_ast);

    $target_cc_str .= &dk_generate_cc_footer($target_srcs_ast);
  }
  #$target_cc_str .= $col . "extern \"C\$nl;
  #$target_cc_str .= $col . "{" . $nl;
  #$col = &colin($col);

  my $info_tbl = {
                  "\#dir" => 'dir',
                  "\#generic-func-ptrs" => 'generic-func-ptrs',
                  "\#get-segment-data" => 'dkt-get-segment-data',
                  "\#imported-klass-names" => 'imported-klass-names',
                  "\#imported-klass-ptrs" =>  'imported-klass-ptrs',
                  "\#interposers" => 'interposers',
                  "\#klass-defns" => 'klass-defns',
                  "\#name" => 'name',
                  "\#selectors" =>  'selectors',
                  "\#signatures" => 'signatures',
                  "\#type" => $$target_srcs_ast{'other'}{'type'},
                  "\#va-generic-func-ptrs" => 'va-generic-func-ptrs',
                  "\#va-selectors" =>  'va-selectors',
                  "\#va-signatures" => 'va-signatures',
                 };
  if (0 < scalar keys %$symbols_from_header) {
    $$info_tbl{"\#include-fors"} = 'include-fors';
  }
  if (0 < scalar keys %{$$target_srcs_ast{'literal-strs'}}) {
    $$info_tbl{"\#str-literals"} = '__str-literals';
    $$info_tbl{"\#str-names"} =    '__str-names';
    $$info_tbl{"\#str-ptrs"} =     '__str-ptrs';
  }
  if (0 < scalar keys %{$$target_srcs_ast{'literal-ints'}}) {
    $$info_tbl{"\#int-literals"} = '__int-literals';
    $$info_tbl{"\#int-names"} =    '__int-names';
    $$info_tbl{"\#int-ptrs"} =     '__int-ptrs';
  }
  $target_cc_str .= $nl;
  $target_cc_str .= "[[read-only]] static char-t   dir-buffer[4096] = \"\";" . $nl;
  $target_cc_str .= "[[read-only]] static str-t    dir = getcwd(dir-buffer, countof(dir-buffer));" . $nl;
  $target_cc_str .= "[[read-only]] static symbol-t name = dk-intern(\"$$target_srcs_ast{'other'}{'name'}\");" . $nl;
  $target_cc_str .= $nl;
  #my $col;
  $target_cc_str .= &generate_target_runtime_info('reg-info', $info_tbl, $col, $$target_srcs_ast{'symbols'}, __LINE__);

  $target_cc_str .= $nl;
  $target_cc_str .= $col . "static func __initial-epilog() -> void {" . $nl;
  $col = &colin($col);
  $target_cc_str .=
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"before\", dir, name);" . $nl .
    $col . "dkt-register-info(&reg-info);" . $nl .
    $col . "DKT-LOG-INITIAL-FINAL(\"'func':'%s','context':'%s','dir':'%s','name':'%s'\", __func__, \"after\",  dir, name);" . $nl .
    $col . "return;" . $nl;
  $col = &colout($col);
  $target_cc_str .= $col . "}" . $nl;
  $target_cc_str .= $col . "static func __final-epilog() -> void {" . $nl;
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
    $col . "static __ddl-t __ddl-epilog = __ddl-t{__initial-epilog, __final-epilog};" . &ann(__FILE__, __LINE__) . $nl;
  return $target_cc_str;
}
sub path::add_last {
  my ($stack, $part) = @_;
  if (0 != @$stack) {
    &add_last($stack, '::');
  }
  &add_last($stack, $part);
}
sub path::remove_last {
  my ($stack) = @_;
  &remove_last($stack); # remove $part

  if (0 != @$stack) {
    &remove_last($stack); # remove '::'
  }
}
sub arg::type {
  my ($arg) = @_;
  if (!defined $arg) {
    $arg = ['void'];
  }
  $arg = join(' ', @$arg);
  $arg = &remove_extra_whitespace($arg);
  return $arg;
}
sub arg_type::super {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;

  my $new_arg_type_ref = &deep_copy($arg_type_ref);

  #if (object-t eq $$new_arg_type_ref[0]) {
  $$new_arg_type_ref[0] = $seq_super_t; # replace_first
  #} else {
  #    $$new_arg_type_ref[0] = 'UNKNOWN-T';
  #}
  return $new_arg_type_ref;
}
sub arg_type::var_args {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;

  my $new_arg_type_ref = &deep_copy($arg_type_ref);
  die if 'va-list-t' ne $$new_arg_type_ref[-1][-1];
  $$new_arg_type_ref[$num_args - 1] = $seq_ellipsis;
  return $new_arg_type_ref;
}
sub arg_type::names {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;
  my $arg_num =        0;
  my $arg_names = [];

  if (0 == &type::compare($seq_super_t, $$arg_type_ref[0])) {
    $$arg_names[0] = "context";    # replace_first
  } else {
    $$arg_names[0] = 'obj';  # replace_first
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    if (0 == &type::compare($seq_ellipsis, $$arg_type_ref[$arg_num])) {
      $$arg_names[$arg_num] = undef;
    } elsif ('va-list-t' eq $$arg_type_ref[$arg_num][-1]) {
      $$arg_names[$arg_num] = "args";
    } else {
      $$arg_names[$arg_num] = "arg$arg_num";
    }
  }
  return $arg_names;
}
sub arg_type::names_unboxed {
  my ($arg_type_ref) = @_;
  my $num_args =       @$arg_type_ref;
  my $arg_num =        0;
  my $arg_names = [];

  my $type_str = &remove_extra_whitespace(join(' ', @{$$arg_type_ref[$arg_num]}));
  if (0) {
  } elsif ('const slots-t*' eq $type_str) {
    $$arg_names[0] = '&mutable-unbox(obj)';
  } elsif ('const slots-t&' eq $type_str) {
    $$arg_names[0] = 'mutable-unbox(obj)';
  } elsif ('slots-t*' eq $type_str) {
    $$arg_names[0] = '&mutable-unbox(obj)';
  } elsif ('slots-t&' eq $type_str) {
    $$arg_names[0] = 'mutable-unbox(obj)';
  } elsif ('slots-t' eq $type_str) {
    $$arg_names[0] = 'unbox(obj)';
  } else {
    $$arg_names[0] = 'obj';
  }

  for ($arg_num = 1; $arg_num < $num_args; $arg_num++) {
    my $type_str = &remove_extra_whitespace(join(' ', @{$$arg_type_ref[$arg_num]}));
    if (0) {
    } elsif ('const slots-t*' eq $type_str) {
      $$arg_names[$arg_num] = "\&unbox(arg$arg_num)";
    } elsif ('const slots-t&' eq $type_str) {
      $$arg_names[$arg_num] = "unbox(arg$arg_num)";
    } elsif ('slots-t*' eq $type_str) {
      $$arg_names[$arg_num] = "\&mutable-unbox(arg$arg_num)";
    } elsif ('slots-t&' eq $type_str) {
      $$arg_names[$arg_num] = "mutable-unbox(arg$arg_num)";
    } elsif ('slots-t' eq $type_str) {
      $$arg_names[$arg_num] = "mutable-unbox(arg$arg_num)";
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
  foreach my $arg (@{$$method{'param-types'}}) {
    if ('va-list-t' ne $$arg[-1]) {
      $result .= $delim . &arg::type($arg);
      $delim = ', '; # extra whitespace
    }
  }
  foreach my $kw_arg (@{$$method{'kw-args'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    my $kw_arg_type = &arg::type($$kw_arg{'type'});

    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default_placeholder = $$kw_arg_placeholders{'default'};
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
  foreach my $arg (@{$$method{'param-types'}}) {
    if ('va-list-t' ne $$arg[-1]) {
      $result .= $delim . &arg::type($arg);
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
  my ($klass_ast) = @_;
  my $method;
  my $va_methods_seq = [];

  #foreach $method (sort method::compare values %{$$klass_ast{'methods'}})
  foreach $method (sort method::compare values %{$$klass_ast{'methods'}}, values %{$$klass_ast{'slots-methods'}}) {
    if (&is_va($method)) {
      &add_last($va_methods_seq, $method);
    }
  }
  return $va_methods_seq;
}
sub klass::kw_arg_methods {
  my ($klass_ast) = @_;
  my $method;
  my $kw_args_methods_seq = [];

  foreach $method (sort method::compare values %{$$klass_ast{'methods'}}) {
    if (&has_kw_args($method)) { # leave, don't change to num_kw_args()
      &add_last($kw_args_methods_seq, $method);
    }
  }
  return $kw_args_methods_seq;
}
sub klass::method_aliases {
  my ($klass_ast) = @_;
  my $method;
  my $method_aliases_seq = [];

  #foreach $method (sort method::compare values %{$$klass_ast{'methods'}})
  foreach $method (sort method::compare values %{$$klass_ast{'methods'}}, values %{$$klass_ast{'slots-methods'}}) {
    if ($$method{'alias-src'}) {
      &add_last($method_aliases_seq, $method);
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
    $visibility = ' [[export]]';
  }
  my $func_spec = '';
  if ($$func{'inline?'}) {
    $func_spec = ' INLINE';
  }
  my $return_type = &arg::type($$func{'return-type'});
  my ($name, $param_types) = &func::overloadsig_parts($func, $scope);
  $func_decl .= $func_spec . "$name($param_types) -> $return_type;";
  return ($visibility, \$func_decl);
}
sub func::overloadsig_parts {
  my ($func, $scope) = @_;
  my $last_item = $$func{'param-types'}[-1];
  my $last_type = &arg::type($last_item);
  my $name = &ct($$func{'name'} || []); # rnielsenrnielsen hackhack
  #if ($name eq '') { return undef; }
  my $param_types = &arg_type::list_types($$func{'param-types'});
  return ($name, $$param_types);
}
sub func::overloadsig {
  my ($func, $scope) = @_;
  my ($name, $param_types) = &func::overloadsig_parts($func, $scope);
  my $func_overloadsig = "$name($param_types)";
  return $func_overloadsig;
}
sub method::var_args_from_qual_va_list {
  my ($method) = @_;
  my $new_method = &deep_copy($method);

  if (&has_va_prefix($new_method)) {
    &remove_name_va_scope($new_method);
  }
  if (exists $$new_method{'param-types'}) {
    &replace_last($$new_method{'param-types'}, $seq_ellipsis);
  }
  return $new_method;
}
sub generate_va_generic_defn {
  #my ($scope, $va_method) = @_;
  my ($va_method, $scope, $col, $klass_type, $max_width, $line) = @_;
  my $pad = '';
  if ($max_width) {
    if (!$$va_method{'defined?'} || &is_src_decl() || &is_target_decl()) {
      my $width = length("@$scope");
      $pad = ' ' x ($max_width - $width);
    }
  }
  my $is_inline =  $$va_method{'inline?'};

  my $new_arg_types_ref =      $$va_method{'param-types'};
  my $new_arg_types_va_ref =   &arg_type::var_args($new_arg_types_ref);
  my $new_arg_names_ref =      &arg_type::names($new_arg_types_ref);
  my $new_arg_names_va_ref =   &arg_type::names($new_arg_types_va_ref);
  my $new_arg_list_va_ref =    &arg_type::list_pair($new_arg_types_va_ref, $new_arg_names_va_ref);
  my $new_arg_names_list_ref = &arg_type::list_names($new_arg_names_ref);

  my $num_args = @$new_arg_names_va_ref;
  my $return_type = &arg::type($$va_method{'return-type'});
  my $va_method_name;

  #if ($$va_method{'alias-dst'}) {
  #$va_method_name = &ct($$va_method{'alias-dst'});
  #}
  #else {
  $va_method_name = &ct($$va_method{'name'});
  #}
  my $scratch_str_ref = &global_scratch_str_ref();
  my $part = '';

  if ($klass_type) {
    $part .= $klass_type . " @$scope" . $pad . " {";
  }
  my $vararg_method = &deep_copy($va_method);
  $$vararg_method{'param-types'} = &arg_type::var_args($$vararg_method{'param-types'});
  my $visibility = '';
  if (&is_exported($va_method)) {
    $visibility = ' [[export]]';
  }
  if (&is_kw_args_method($vararg_method)) {
    $part .= ' [[sentinel]]';
  }
  my $func_spec = '';
  if ($is_inline) {
    $func_spec = ' INLINE';
  }
  $part .= $visibility . $func_spec;
  if ($klass_type) {
    $part .= ' METHOD';
  }
  else {
    $part .= ' func';
  }
  $part .= ' ';
  if (! $klass_type) {
    $part .= '$';
  }
  $part .= "$va_method_name($$new_arg_list_va_ref) -> $return_type";

  if (!$$va_method{'defined?'} || &is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= $col . $part . ";" . &ann(__FILE__, $line) . $nl;
  } elsif ($$va_method{'defined?'} && (&is_target_defn())) {
    $$scratch_str_ref .= $col . $part;
    my $name = &last($$va_method{'name'});
    my $va_name = "_func_";
    &replace_last($$va_method{'name'}, $va_name);
    my $method_type_decl = &method::type_decl($va_method);
    &replace_last($$va_method{'name'}, $name);
    my $scope_str = &ct($scope);
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .=
      $col . "static func $method_type_decl = \$va::$va_method_name;" . $nl .
      $col . "$va_list_t args;" . $nl .
      $col . "va-start(args, $$new_arg_names_ref[$num_args - 2]);" . $nl;

    if (defined $$va_method{'return-type'}) {
      my $return_type = &arg::type($$va_method{'return-type'});
      $$scratch_str_ref .= $col . "auto result =";
    } else {
      $$scratch_str_ref .= $col . "";
    }

    $$scratch_str_ref .=
      " $va_name($$new_arg_names_list_ref);" . $nl .
      $col . "va-end(args);" . $nl;

    if (defined $$va_method{'return-type'}) {
      $$scratch_str_ref .= $col . "return result;" . $nl;
    } else {
      $$scratch_str_ref .= $col . "return;" . $nl;
    }
    $col = &colout($col);
    $$scratch_str_ref .= $col . "}" . $nl;
  }
  if ($klass_type) {
    $$scratch_str_ref .= " }";
  }
}
sub method::compare {
  my $scope;
  my $a_string = &func::overloadsig($a, $scope = []); # the a and b values sometimes
  my $b_string = &func::overloadsig($b, $scope = []); # are missing the 'name' key

  $a_string =~ s/(.*?$va_list_t.*?)/ $1/;
  $b_string =~ s/(.*?$va_list_t.*?)/ $1/;

  $a_string cmp $b_string;
}
sub symbol::compare {
  $a cmp $b;
}
sub string::compare {
  $a cmp $b;
}
sub type::compare {
  my ($a, $b) = @_;
  return &ct($a) cmp &ct($b);
}
sub property::compare {
  my ($a_key, $a_val) = %$a;
  my ($b_key, $b_val) = %$b;
  $a_key cmp $b_key;
}
sub common::print_signature {
  my ($generic, $col, $path) = @_;
  my $new_arg_type = $$generic{'param-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $$new_arg_type_list = &remove_extra_whitespace($$new_arg_type_list);

  my $scratch_str = "";
  if (&is_va($generic)) {
    $scratch_str .= $col . 'namespace va { INLINE func';
  } else {
    $scratch_str .= $col . 'INLINE func';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = ' [[export]]';
  }
  my $generic_name = &ct($$generic{'name'});
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . " $generic_name($$new_arg_type_list) -> const signature-t*";
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
    my $arg_list =    "static const signature-t result = { .name =        \"$name_str\"," . $nl .
      (' ' x $padlen) . ".param-types = \"$$new_arg_type_list\"," . $nl .
      (' ' x $padlen) . ".return-type = \"$return_type_str\" };" . $nl;
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
      my $kw_args = $$generic{'kw-args'} || undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_signature($generic, $col, ['signature', ':', 'va']);
      }
      $$generic{'kw-args'} = $kw_args;
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
        my $kw_args = $$var_args_generic{'kw-args'} || undef;
        #if (!&is_slots($var_args_generic)) {
        $scratch_str .= &common::print_signature($var_args_generic, $col, ['signature']);
        #}
        $$var_args_generic{'kw-args'} = $kw_args;
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
      my $kw_args = $$generic{'kw-args'} || undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_signature($generic, $col, ['signature']);
      }
      $$generic{'kw-args'} = $kw_args;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  return $scratch_str;
}
sub common::print_selector {
  my ($generic, $col, $path) = @_;
  my $new_arg_type = $$generic{'param-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $$new_arg_type_list = &remove_extra_whitespace($$new_arg_type_list);

  my $scratch_str = "";
  if (&is_va($generic)) {
    $scratch_str .= $col . 'namespace va { INLINE func';
  } else {
    $scratch_str .= $col . 'INLINE func';
  }
  my $visibility = '';
  if (&is_exported($generic)) {
    $visibility = ' [[export]]';
  }
  my $generic_name = &ct($$generic{'name'});
  my $in = &ident_comment($generic_name);
  $scratch_str .= $visibility . " $generic_name($$new_arg_type_list) -> selector-t*";
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
    my $param_types_str = $$new_arg_type_list;
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
      my $kw_args = $$generic{'kw-args'} || undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_selector($generic, $col, ['__selector', '::', 'va']);
      }
      $$generic{'kw-args'} = $kw_args;
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
        my $kw_args = $$var_args_generic{'kw-args'} || undef;
        if (!&is_slots($generic)) {
          $scratch_str .= &common::print_selector($var_args_generic, $col, ['__selector']);
        }
        $$var_args_generic{'kw-args'} = $kw_args;
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
      my $kw_args = $$generic{'kw-args'} || undef;
      if (!&is_slots($generic)) {
        $scratch_str .= &common::print_selector($generic, $col, ['__selector']);
      }
      $$generic{'kw-args'} = $kw_args;
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
        &add_last($va_generics, $generic);
      } else {
        &add_last($fa_generics, $generic);
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
    $scratch_str .= $col . "static generic-func-t*[] va-generic-func-ptrs = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list = &arg_type::list_types($$generic{'param-types'});
      my $generic_name = &ct($$generic{'name'});
      my $in = &ident_comment($generic_name);
      $scratch_str .= $col . "GENERIC-FUNC-PTR-PTR(\$va::$generic_name($$new_arg_type_list))," . $in . $nl;
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static generic-func-t** generic-func-ptrs = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static generic-func-t*[] generic-func-ptrs = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list = &arg_type::list_types($$generic{'param-types'});
        my $generic_name = &ct($$generic{'name'});
        my $in = &ident_comment($generic_name);
        $scratch_str .= $col . "GENERIC-FUNC-PTR-PTR(\$$generic_name($$new_arg_type_list))," . $in . $nl;
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
    $scratch_str .= $col . "static const signature-t* const[] va-signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list = &arg_type::list_types($$generic{'param-types'});
      my $generic_name = &ct($$generic{'name'});
      my $in = &ident_comment($generic_name);
      $scratch_str .= $col . "signature(va::$generic_name($$new_arg_type_list))," . $in . $nl;
    }
    $scratch_str .= $col . "nullptr," . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  if (0 == @$fa_generics) {
    $scratch_str .= $col . "static const signature-t* const* signatures = nullptr;" . $nl;
  } else {
    $scratch_str .= $col . "static const signature-t* const[] signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list = &arg_type::list_types($$generic{'param-types'});
        my $generic_name = &ct($$generic{'name'});
        my $in = &ident_comment($generic_name);
        $scratch_str .= $col . "signature($generic_name($$new_arg_type_list))," . $in . $nl;
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
    $scratch_str .= $col . "static selector-node-t[] va-selectors = { //rw-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (sort method::compare @$va_generics) {
      my $new_arg_type_list =   &arg_type::list_types($$generic{'param-types'});
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
    $scratch_str .= $col . "static selector-node-t[] selectors = { //rw-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach $generic (@$fa_generics) {
      if (!&is_slots($generic)) {
        my $new_arg_type_list =   &arg_type::list_types($$generic{'param-types'});
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
      &path::add_last($scope, $ns) if ($ns);
      my $new_generic = &deep_copy($generic);
      $$new_generic{'inline?'} = $is_inline;

      $$new_generic{'defined?'} = 1; # hackhack

      my ($klass_type, $max_width);
      &generate_va_generic_defn($new_generic, $scope, $col, $klass_type = undef, $max_width = undef, __LINE__); # object-t
      $$new_generic{'param-types'}[0] = $seq_super_t; # replace_first
      &generate_va_generic_defn($new_generic, $scope, $col, $klass_type = undef, $max_width = undef, __LINE__); # super-t
      &path::remove_last($scope);
    }
  }
}
my $big_generic = 0;
sub generate_generic_defn {
  my ($generic, $is_inline, $col, $ns) = @_;
  my $generic_name = $$generic{'name'}[0];
  my $orig_arg_type_list = &arg_type::list_types($$generic{'param-types'});
  my $tmp = &deep_copy($$generic{'param-types'}[0]);
  $$generic{'param-types'}[0] = $seq_object_t;
  my $new_arg_type =            $$generic{'param-types'};
  my $new_arg_type_list =   &arg_type::list_types($new_arg_type);
  $$generic{'param-types'}[0] = $tmp;
  $new_arg_type =            $$generic{'param-types'};
  my $new_arg_names =           &arg_type::names($new_arg_type);
  my $new_arg_list =            &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$generic{'return-type'});
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_va_prefix_method = '';
  my $opt_name_prefix = '$';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = ' namespace $va {';
    $opt_va_prefix = '$va::';
    $opt_va_prefix_method = 'va::';
    $opt_name_prefix = '';
    $opt_va_close = '}'
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  my $in = &ident_comment($generic_name);
  $$scratch_str_ref .= $col . '// ' . $opt_va_prefix . $opt_name_prefix . $generic_name . '(' . $$orig_arg_type_list . ')' . ' -> ' . $return_type . $nl;
  my $part = 'namespace __generic-func {' . $opt_va_open . ' STATIC INLINE func ' . $opt_name_prefix . $generic_name . '(' . $$new_arg_list . ") -> $return_type";

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= $col . $part . "; }" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= $col . $part . " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .= $col . "typealias func-t = func (*)($$new_arg_type_list) -> $return_type;" . ' // no runtime cost' . $nl;
    $$scratch_str_ref .= $col . "static selector-t selector = selector($opt_va_prefix_method$generic_name($$new_arg_type_list));" . ' // one time initialization' . $nl;
    if (&is_super($generic)) {
      $$scratch_str_ref .= $col . "func-t _func_ = cast(func-t)klass::unbox(superklass-of(context.kls)).methods.addrs[selector];" . $nl;
    } else {
      $$scratch_str_ref .= $col . "func-t _func_ = cast(func-t)klass::unbox(klass-of(obj)).methods.addrs[selector];" . $nl;
    }
    my $arg_names_list;
    if ($big_generic) {
      my $arg_names = &deep_copy(&arg_type::names(&deep_copy($$generic{'param-types'})));
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
      &replace_first($new_arg_names, "context.obj");
    }
    my $new_arg_names_list = &arg_type::list_names($new_arg_names);

    $$scratch_str_ref .= $col . "auto result = _func_($$new_arg_names_list);" . $nl;
    $$scratch_str_ref .= $col . "return result;" . $nl;
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
  my $list_types_str_ref = &arg_type::list_types($$generic{'param-types'});
  my $return_type_str = &remove_extra_whitespace(join(' ', @{$$generic{'return-type'}}));
  my $in = &ident_comment($generic_name);
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_name_prefix = '$';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = ' namespace $va {';
    $opt_va_prefix = '$va::';
    $opt_name_prefix = '';
    $opt_va_close = '}'
  }
  #namespace __generic-func-ptr { INLINE func add(object-t, object-t) -> generic-func-t* {
  #  typealias func-t = func (*)(object-t, object-t) -> object-t; // no runtime cost
  #    static generic-func-t result = cast(generic-func-t)cast(func-t)__generic-func::add;
  #  return &result;
  #}}
  my $scratch_str_ref = &global_scratch_str_ref();
  my $part = 'namespace __generic-func-ptr {' . $opt_va_open . ' STATIC INLINE func ' . $opt_name_prefix . $generic_name . '(' . $$list_types_str_ref . ') -> generic-func-t*';

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= $col . $part . "; }" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= $col . $part . " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .= $col . "typealias func-t = func (\*)($$list_types_str_ref) -> $return_type_str;" . ' // no runtime cost' . $nl;
    $$scratch_str_ref .= $col . 'static generic-func-t result = cast(generic-func-t)cast(func-t)(__generic-func::' . $opt_va_prefix . $opt_name_prefix . $generic_name . ');' . $nl;
    $$scratch_str_ref .= $col . 'return &result;' . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . '}}' . $opt_va_close . $nl;
  }
}
sub is_tuple_type {
  my ($type) = @_;
  if ($type =~ /^(<|\[)/) { return 1; }
  else { return 0; }
}
sub make_tuple_type {
  my ($type) = @_;
  if (&is_tuple_type($type)) {
    $type =~ s/^(<|\[)(.+?)(>|\])$/$2/;
    $type = 'std::tuple<' . $type . '>';
  }
  return $type;
}
sub generate_generic_func_defn {
  my ($generic, $is_inline, $col, $ns) = @_;
  my $generic_name = $$generic{'name'}[0];
  my $list_types_str_ref = &arg_type::list_types($$generic{'param-types'});
  my $tmp = &deep_copy($$generic{'param-types'}[0]);
  $$generic{'param-types'}[0] = $seq_object_t;
  my $new_arg_type =            $$generic{'param-types'};
  my $new_arg_type_list =   &arg_type::list_types($new_arg_type);
  $$generic{'param-types'}[0] = $tmp;
  my $list_names = &arg_type::names($$generic{'param-types'});
  my $list_names_str = join(', ', @$list_names);
  my $arg_list =  &arg_type::list_pair($$generic{'param-types'}, $list_names);
  my $return_type_str = &remove_extra_whitespace(join(' ', @{$$generic{'return-type'}}));
  my $in = &ident_comment($generic_name);
  my $opt_va_open = '';
  my $opt_va_prefix = '';
  my $opt_va_prefix_method = '';
  my $opt_name_prefix = '$';
  my $opt_va_close = '';
  if (&is_va($generic)) {
    $opt_va_open = ' namespace $va {';
    $opt_va_prefix = '$va::';
    $opt_va_prefix_method = 'va::';
    $opt_name_prefix = '';
    $opt_va_close = '}'
  }
  #namespace $ns { INLINE generic-func add(object-t arg0, object-t arg1) -> object-t {
  #  typealias func-t = func (*)(object-t, object-t) -> object-t; // no runtime cost
  #  func-t _func_ = cast(func-t)GENERIC-FUNC(add(object-t, object-t)); // static would be faster, but more rigid
  #  return _func_(arg0, arg1);
  #}}
  my $scratch_str_ref = &global_scratch_str_ref();
  my $part = $opt_va_open . ' INLINE func ' . $opt_name_prefix . $generic_name . '(' . $$arg_list . ') -> ' . $return_type_str;

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= $col . $part . ";" . $opt_va_close . &ann(__FILE__, __LINE__) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= $col . $part . " {" . $in . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $$scratch_str_ref .= $col . "typealias func-t = func (\*)($$list_types_str_ref) -> $return_type_str;" . ' // no runtime cost' . $nl;
    $$scratch_str_ref .= $col . "DEBUG-STMT(static const signature-t* signature = signature($opt_va_prefix_method$generic_name($$new_arg_type_list)));" . ' // one time initialization' . $nl;
    $$scratch_str_ref .= $col . "DEBUG-STMT(dkt-current-signature = signature);" . $nl;
    if (&is_super($generic)) {
      $$scratch_str_ref .= $col . "DEBUG-STMT(dkt-current-context-klass = context.kls);" . $nl;
    } else {
      $$scratch_str_ref .= $col . "DEBUG-STMT(dkt-current-context-klass = nullptr);" . $nl;
    }
    $$scratch_str_ref .= $col . 'func-t _func_ = cast(func-t)GENERIC-FUNC-PTR(' . $opt_va_prefix . $opt_name_prefix . $generic_name . '(' . $$list_types_str_ref . '));' . $nl;
    $return_type_str = &make_tuple_type($return_type_str);
    $$scratch_str_ref .= $col . 'auto result = _func_(' . $list_names_str . ');' . $nl;
    $$scratch_str_ref .= $col . "DEBUG-STMT(dkt-current-signature = nullptr);" . $nl;
    if (&is_super($generic)) {
      $$scratch_str_ref .= $col . "DEBUG-STMT(dkt-current-context-klass = nullptr);" . $nl;
    }
    $$scratch_str_ref .= $col . 'return result;' . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . '}' . $opt_va_close . $nl;
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
        $$copy{'param-types'}[0] = $seq_super_t;
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
  &generate_va_generic_defns($generics, $is_inline = 1, $col, $ns);
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
        $$copy{'param-types'}[0] = $seq_super_t;
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
  my ($generics, $col) = @_;
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
  my ($ast, $col) = @_;
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  my ($is_inline, $ns);
  &generate_generic_defns($ast, $is_inline = 0, $col, $ns = undef);
  return $$scratch_str_ref;
}
my $enum_set = { 'type-enum' => 1,
                 'enum'      => 1 };
my $struct_union_set = { 'struct' => 1,
                         'union'  => 1 };
## exists()  (does this key exist)
## defined() (is the value (for this key) non-undef)
sub slots_decl {
  my ($slots_ast) = @_;
  my $result = ' slots';
  if ($$slots_ast{'cat'}) {
    if ('struct' ne $$slots_ast{'cat'}) {
      $result .= ' ' . $$slots_ast{'cat'};
    }
    if ($$enum_set{$$slots_ast{'cat'}}) {
      if ($$slots_ast{'enum-base'}) {
        $result .= ' : ' . join('', @{$$slots_ast{'enum-base'}});
      } else {
        $result .= ' : ' . 'int-t';
      }
    }
  } elsif ($$slots_ast{'type'}) {
    $result .= ' ' . $$slots_ast{'type'};
  }
  return $result;
}
sub generate_struct_or_union_decl {
  my ($col, $slots_ast, $is_exported, $is_slots) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $slots_cat_info = $$slots_ast{'cat-info'};

  if ($$struct_union_set{$$slots_ast{'cat'}}) {
    $$scratch_str_ref .= &slots_decl($slots_ast) . '; ';
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
}
sub generate_struct_or_union_defn {
  my ($col, $slots_ast, $is_exported, $is_slots) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $slots_cat_info = $$slots_ast{'cat-info'};

  if ($$struct_union_set{$$slots_ast{'cat'}}) {
    $$scratch_str_ref .= &slots_decl($slots_ast) . ' {' . &ann(__FILE__, __LINE__) . $nl;
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }

  my $max_width = 0;
  foreach my $slot_cat_info (@$slots_cat_info) {
    my $width = length($$slot_cat_info{'type'});
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $slot_cat_info (@$slots_cat_info) {
    my $width = length($$slot_cat_info{'type'});
    my $pad = ' ' x ($max_width - $width);
    if (defined $$slot_cat_info{'expr'}) {
      $$scratch_str_ref .= $col . "$$slot_cat_info{'type'}" . $pad . " $$slot_cat_info{'name'} = $$slot_cat_info{'expr'};" . $nl;
    } else {
      $$scratch_str_ref .= $col . "$$slot_cat_info{'type'}" . $pad . " $$slot_cat_info{'name'};" . $nl;
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '}';
}
sub generate_enum_decl {
  my ($col, $enum, $is_exported, $is_slots) = @_;
  die if $$enum{'type'} && $is_slots;
  my $cat = $$enum{'cat'};
  my $info = $$enum{'cat-info'};
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($is_slots) {
    $$scratch_str_ref .= ' slots ' . $cat;
  }
  elsif ($$enum{'type'}) {
    $$scratch_str_ref .= ' ' . $cat . ' ' . join('', @{$$enum{'type'}});
  } else {
    $$scratch_str_ref .= ' ' . $cat;
  }
  if ($$enum{'enum-base'}) {
    $$scratch_str_ref .= ' : ' . join('', @{$$enum{'enum-base'}});
  } elsif ('type-enum' ne $cat) {
    $$scratch_str_ref .= ' : int-t'; # default enum base
  }
  $$scratch_str_ref .= ';';
}
sub generate_enum_defn {
  my ($col, $enum, $is_exported, $is_slots) = @_;
  die if $$enum{'type'} && $is_slots;
  my $cat = $$enum{'cat'};
  my $slots_cat_info = $$enum{'cat-info'};
  my $scratch_str_ref = &global_scratch_str_ref();

  if ($is_slots) {
    $$scratch_str_ref .= ' slots ' . $cat;
  }
  elsif ($$enum{'type'}) {
    $$scratch_str_ref .= ' ' . $cat . ' ' . join('', @{$$enum{'type'}});
  } else {
    $$scratch_str_ref .= ' ' . $cat;
  }
  if ($$enum{'enum-base'}) {
    $$scratch_str_ref .= ' : ' . join('', @{$$enum{'enum-base'}});
  } elsif ('type-enum' ne $cat) {
    $$scratch_str_ref .= ' : int-t'; # default enum base
  }
  $$scratch_str_ref .= ' {' . &ann(__FILE__, __LINE__) . $nl;
  my $max_width = 0;
  foreach my $slot_cat_info (@$slots_cat_info) {
    my $width = length($$slot_cat_info{'name'});
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $slot_cat_info (@$slots_cat_info) {
    if (defined $$slot_cat_info{'expr'}) {
      my $width = length($$slot_cat_info{'name'});
      my $pad = ' ' x ($max_width - $width);
      $$scratch_str_ref .= $col . "$$slot_cat_info{'name'} =" . $pad . " $$slot_cat_info{'expr'}," . $nl;
    } else {
      $$scratch_str_ref .= $col . "$$slot_cat_info{'name'}," . $nl;
    }
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . '};';
}
sub param_list_from_slots_cat_info {
  my ($slots_cat_info) = @_;
  my $names = '';
  my $pairs = '';
  my $pairs_w_expr = '';
  my $sep = '';

  foreach my $slot_cat_info (@$slots_cat_info) {
    my $type = $$slot_cat_info{'type'};
    my $name = $$slot_cat_info{'name'};
   #$names .=        "$sep/*.$name =*/ _$name";
    $names .=        "$sep.$name = _$name";
    $pairs .=        "$sep$type _$name";
    $pairs_w_expr .= "$sep$type _$name";
    $sep = ', ';

    if (defined $$slot_cat_info{'expr'}) {
     #$pairs_w_expr .= " /*= $$slot_cat_info{'expr'}*/";
      $pairs_w_expr .= " = $$slot_cat_info{'expr'}";
    }
  }
  return ($names, $pairs, $pairs_w_expr);
}
sub has_object_method_defn {
  my ($klass_ast, $slots_method_info) = @_;
  my $result = 0;

  my $object_method_info = &convert_to_object_method($slots_method_info);
  my $object_method_sig = &func::overloadsig($object_method_info, []);

  if ($$klass_ast{'methods'}{$object_method_sig} &&
      $$klass_ast{'methods'}{$object_method_sig}{'defined?'}) {
    $result = 1;
  }
  return $result;
}
sub generate_klass_unbox {
  my ($klass_path, $klass_name, $is_klass_defn) = @_;
  my $result = '';
  my $col = '';
  my $special_cases = { 'object' => 1,
                        'klass'  => 1 };
  if (! $$special_cases{$klass_name}) {
    ### unbox() same for all types
    my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
    if ($is_klass_defn || (&should_export_slots($klass_ast) && &has_slots_cat_info($klass_ast))) {
      $result .= $col . "klass $klass_name { [[UNBOX-ATTRS]] INLINE func mutable-unbox($object_t obj) -> slots-t&";
      if (&is_src_decl() || &is_target_decl()) {
        $result .= "; }" . &ann(__FILE__, __LINE__) . $nl; # general-case
      } elsif (&is_target_defn()) {
        $result .=
          " {" . &ann(__FILE__, __LINE__) . $nl .
          $col . "  DKT-UNBOX-CHECK(obj, _klass_); // optional" . $nl .
          $col . "  slots-t& s = *cast(slots-t*)(cast(intptr-t)obj + klass::unbox(_klass_).offset);" . $nl .
          $col . "  return s;" . $nl .
          $col . "}} // $klass_name\::mutable-unbox()" . $nl;
      }

      $result .= $col . "klass $klass_name { [[UNBOX-ATTRS]] INLINE func unbox($object_t obj) -> const slots-t&";
      if (&is_src_decl() || &is_target_decl()) {
        $result .= "; }" . &ann(__FILE__, __LINE__) . $nl; # general-case
      } elsif (&is_target_defn()) {
        $result .=
          " {" . &ann(__FILE__, __LINE__) . $nl .
          $col . "  const slots-t& s = mutable-unbox(obj);" . $nl .
          $col . "  return s;" . $nl .
          $col . "}} // $klass_name\::unbox()" . $nl;
      }
    }
  }
  return $result;
}
sub generate_klass_box {
  my ($klass_ast, $klass_path, $klass_name) = @_;
  my $result = '';
  if (!&has_slots_defn($klass_ast)) {
    return $result;
  }
  my $col = '';

  if ('object' ne &ct($klass_path)) {
    if (&should_export_slots($klass_ast)) {
      ### box()
      my $slots_type = &at($$klass_ast{'slots'}, 'type');
      if (&is_array_type($slots_type)) {
        ### box() array-type
        $result .= $col . "klass $klass_name { INLINE func box(const slots-t arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "$object_t result = \$make(klass());" . $nl .
            $col . "memcpy(mutable-unbox(result), arg, sizeof(slots-t)); // unfortunate" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(const slots-t)" . $nl;
        }

        $result .= $col . "klass $klass_name { INLINE func box(slots-t arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "$object_t result = $klass_name\::box(cast(std::decay<const slots-t>::type)arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(slots-t)" . $nl;
        }

        $result .= $col . "klass $klass_name { INLINE func box(const slots-t* arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "$object_t result = $klass_name\::box(*arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(const slots-t*)" . $nl;
        }
        $result .= $col . "klass $klass_name { INLINE func box(slots-t* arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "$object_t result = $klass_name\::box(cast(const slots-t*)*arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(slots-t*)" . $nl;
        }
      } else { # !&is_array_type()
        ### box() non-array-type
        $result .= $col . "klass $klass_name { INLINE func box(const slots-t* arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          if ($$klass_ast{'init-supports-kw-slots?'}) {
            my $kw_arg_name = $$klass_ast{'init-supports-kw-slots?'};
            my $type = "$klass_name\::slots-t";
              $result .=
                $col . "$object_t result = \$make(klass(), \#$kw_arg_name : *arg);" . $nl;
          } else {
            $result .=
              $col . "$object_t result = \$make(klass());" . $nl .
              $col . "mutable-unbox(result) = *arg;" . $nl;
          }
          $result .= $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(const slots-t*)" . $nl;
        }

        $result .= $col . "klass $klass_name { INLINE func box(slots-t* arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .= $col . "object-t result = $klass_name\::box(cast(const slots-t*)arg);" . $nl;
          $result .= $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(slots-t*)" . $nl;
        }

        $result .= $col . "klass $klass_name { INLINE func box(slots-t arg) -> $object_t";

        if (&is_src_decl() || &is_target_decl()) {
          $result .= "; }" . &ann(__FILE__, __LINE__) . $nl;
        } elsif (&is_target_defn()) {
          $result .= " {" . &ann(__FILE__, __LINE__) . $nl;
          $col = &colin($col);
          $result .=
            $col . "$object_t result = $klass_name\::box(&arg);" . $nl .
            $col . "return result;" . $nl;
          $col = &colout($col);
          $result .= $col . "}} // $klass_name\::box(const slot-t)" . $nl;
        }
      }
    }
  }
  if ((&is_src_decl() || &is_target_decl) && &should_export_slots($klass_ast) && &has_slots_type($klass_ast)) {
    $result .= $col . "using $klass_name\::box;" . &ann(__FILE__, __LINE__) . $nl;
  }
  return $result;
}
sub generate_klass_construct {
  my ($klass_ast, $klass_name) = @_;
  my $result = '';
  my $col = '';
  my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
  my $slots_cat_info = &at($$klass_ast{'slots'}, 'cat-info');
  if ($slots_cat && ('struct' eq $slots_cat)) {
    if ($ENV{'DK_NO_COMPOUND_LITERALS'}) {
      if (&has_slots_cat_info($klass_ast)) {
        my ($names, $pairs, $pairs_w_expr) = &param_list_from_slots_cat_info($slots_cat_info);
        #print "generate-klass-construct: " . &Dumper($slots_cat_info);

        if ($pairs =~ m/\[/g) {
        } else {
          if (&is_src_decl() || &is_target_decl()) {
            $result .= $col . "klass $klass_name { func construct($pairs_w_expr) -> slots-t; }" . &ann(__FILE__, __LINE__) . $nl;
          } elsif (&is_target_defn()) {
            $result .= $col . "klass $klass_name { func construct($pairs) -> slots-t {" . &ann(__FILE__, __LINE__) . $nl;
            $col = &colin($col);
            $result .=
              $col . "auto result = cast(slots-t){ $names };" . $nl .
              $col . "return result;" . $nl;
            $col = &colout($col);
            $result .= $col . "}} // $klass_name\::construct()" . $nl;
          }
        }
      }
    }
  }
  return $result;
}
sub linkage_unit::generate_klasses_body_vars {
  my ($klass_ast, $col, $klass_type, $klass_path, $klass_name, $max_width, $should_ann) = @_;
  my $width = length($klass_name);
  my $pad = ' ' x ($max_width - $width);
  my $scratch_str_ref = &global_scratch_str_ref();

  if (&is_src_decl() || &is_target_decl()) {
    #$$scratch_str_ref .= $col . "extern symbol-t __type__;" . $nl;
    $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { extern symbol-t __name__;";
  } elsif (&is_target_defn()) {
    #$$scratch_str_ref .= $col . "symbol-t __type__ = \$$klass_type;" . $nl;
    my $literal_symbol = &as_literal_symbol(&ct($klass_path));
    $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { symbol-t __name__ = $literal_symbol;";
  }
  if ('klass' eq $klass_type) { # not a trait
    if (&is_src_decl() || &is_target_decl()) {
      $$scratch_str_ref .= " [[read-only]] extern $object_t _klass_;";
    } elsif (&is_target_defn()) {
      $$scratch_str_ref .= $pad . " $object_t _klass_ = nullptr;";
    }
  }
  $$scratch_str_ref .= ' }' . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
    if (!&is_target_defn()) {
      my $is_exported;
      if (exists $$klass_ast{'const'}) {
        foreach my $const (@{$$klass_ast{'const'}}) {
          $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { extern const $$const{'type'} $$const{'name'}; }" . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
        }
      }
    }
}
sub linkage_unit::generate_klasses_body_funcs_klass {
  my ($klass_ast, $col, $klass_type, $klass_path, $klass_name) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();

  if ('trait' eq $klass_type) {
    if (&is_src_decl() || &is_target_decl()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { INLINE func klass($object_t) -> $object_t; }" . &ann(__FILE__, __LINE__) . $nl;
    } elsif (&is_target_defn()) {
      $$scratch_str_ref .= $col . "$klass_type $klass_name { INLINE func klass($object_t self) -> $object_t { return klass-with-trait(klass-of(self), __name__); }}" . &ann(__FILE__, __LINE__) . $nl;
    }
  } elsif ('klass' eq $klass_type) { # not a trait
    if (&is_src_decl() || &is_target_decl()) {
      $$scratch_str_ref .= "$klass_type $klass_name { INLINE func klass() -> $object_t; }" . &ann(__FILE__, __LINE__) . $nl;
    } elsif (&is_target_defn()) {
      $$scratch_str_ref .= "$klass_type $klass_name { INLINE func klass() -> $object_t { return klass-for-name(__name__, _klass_); }}" . &ann(__FILE__, __LINE__) . $nl;
    }
  } else { die }
}
sub linkage_unit::generate_klasses_body_funcs_box {
  my ($klass_ast, $col, $klass_type, $klass_path, $klass_name) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();

  if ('klass' eq $klass_type) {
    if (&has_slots($klass_ast)) {
      $$scratch_str_ref .= &generate_klass_box($klass_ast, $klass_path, $klass_name);
    } # if (&has_slots()
  }
}
sub linkage_unit::generate_klasses_body_funcs {
  my ($klass_ast, $col, $klass_type, $klass_path, $klass_name) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();

  if ('klass' eq $klass_type) {
    if (&has_slots($klass_ast)) {
      my $is_klass_defn = scalar keys %$klass_ast;
      $$scratch_str_ref .= &generate_klass_unbox($klass_path, $klass_name, $is_klass_defn);
    } # if (&has_slots()
    my $object_method_defns = {};
    foreach my $method (sort method::compare values %{$$klass_ast{'slots-methods'}}) {
      if (&is_src_defn() || &is_target_defn() || &is_exported($method)) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'param-types'}[0])) {
            my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
            #$$scratch_str_ref .= $col . "$klass_type $klass_name {" . $visibility . " METHOD $$method_decl_ref } // REMOVE" . &ann(__FILE__, __LINE__) . $nl;
            if (!&has_object_method_defn($klass_ast, $method)) {
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
          $$scratch_str_ref .= $col . "$klass_type $klass_name {" . $visibility . " METHOD $$method_decl_ref } // DUPLICATE" . &ann(__FILE__, __LINE__) . $nl;
          my $object_method = &convert_to_object_method($method);
          my $sig = &func::overloadsig($object_method, []);
          if (!$$object_method_defns{$sig}) {
            &generate_object_method_decl($method, $klass_path, $col, $klass_type, __LINE__);
          }
          $$object_method_defns{$sig} = 1;
        }
      }
    }
    my $exported_slots_methods = &exported_slots_methods($klass_ast);
    foreach my $method (sort method::compare values %$exported_slots_methods) {
      die if !&is_exported($method);
      if (&is_src_defn() || &is_target_defn()) {
        if (!&is_va($method)) {
          if (&is_box_type($$method{'param-types'}[0])) {
            my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
            $$scratch_str_ref .= $col . "$klass_type $klass_name {" . $visibility . " METHOD $$method_decl_ref }" . &ann(__FILE__, __LINE__) . $nl;
            if (!&has_object_method_defn($klass_ast, $method)) {
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
    if (&should_export_slots($klass_ast)) {
      $$scratch_str_ref .= &generate_klass_construct($klass_ast, $klass_name);
    }
  } # if ('klass' eq $klass_type)
  #foreach $method (sort method::compare values %{$$klass_ast{'methods'}})
  foreach my $method (sort method::compare values %{$$klass_ast{'methods'}}, values %{$$klass_ast{'slots-methods'}}) {
    if (&is_decl) {
      if (&is_same_src_file($klass_ast) || &is_target()) { #rn3
        if (!&is_va($method)) {
          my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
          $$scratch_str_ref .= $col . "$klass_type $klass_name {" . $visibility . " METHOD $$method_decl_ref } // DUPLICATE" . &ann(__FILE__, __LINE__) . $nl;
        }
      }
    }
  }
}
sub linkage_unit::generate_klasses_body_funcs_non_inline {
  my ($klass_ast, $col, $klass_type, $klass_path, $klass_name, $max_width) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $width = length($klass_name);
  my $pad = ' ' x ($max_width - $width);

  my $va_list_methods = &klass::va_list_methods($klass_ast);
  if (&is_decl() && $$klass_ast{'has-initialize'}) {
    $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { func initialize($object_t kls) -> void; }" . &ann(__FILE__, __LINE__) . $nl;
  }
  if (&is_decl() && $$klass_ast{'has-finalize'}) {
    $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { func finalize($object_t kls) -> void; }" . &ann(__FILE__, __LINE__) . $nl;
  }
  my $kw_arg_methods = &klass::kw_arg_methods($klass_ast);
  if (&is_decl() && @$kw_arg_methods) {
    &generate_kw_arg_method_signature_decls($$klass_ast{'methods'}, [ $klass_name ], $col, $klass_type, $max_width);
  }
  if (&is_decl() && defined $$klass_ast{'slots-methods'}) {
    &generate_slots_method_signature_decls($$klass_ast{'slots-methods'}, [ $klass_name ], $col, $klass_type, $max_width);
  }
  if (&is_target() && !&is_decl() && defined $$klass_ast{'slots-methods'}) {
    &generate_slots_method_signature_defns($$klass_ast{'slots-methods'}, [ $klass_name ], $col, $klass_type);
  }
  if (&is_decl() && @$va_list_methods) { #rn0
    #print STDERR Dumper($va_list_methods);
    foreach my $method (@$va_list_methods) {
      my ($visibility, $method_decl_ref) = &func::decl($method, $klass_path);
      if (&num_kw_args($method)) {
        $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { namespace va {" . $visibility . " METHOD $$method_decl_ref }} //kw-args // stmt1" . &ann(__FILE__, __LINE__) . $nl;
      } else {
        $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " { namespace va {" . $visibility . " METHOD $$method_decl_ref }} //va // stmt1" . &ann(__FILE__, __LINE__) . $nl;
      }
    }
  }
  if (@$va_list_methods) {
    foreach my $method (@$va_list_methods) {
      if (1) {
        my $va_method = &deep_copy($method);
        #$$va_method{'inline?'} = 1;
        #if (&is_decl() || &is_same_file($klass_ast)) #rn1
        if (&is_same_src_file($klass_ast) || &is_decl()) { #rn1
          if (&has_kw_args($method)) { # leave, don't change to num_kw_args() (only missing-prototype warning)
            &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, $max_width, __LINE__);
            if (0 == &num_kw_args($va_method)) {
              my $last = &remove_last($$va_method{'param-types'});
              die if 'va-list-t' ne $$last[-1];
              my ($visibility, $method_decl_ref) = &func::decl($va_method, $klass_path);
              $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " {" . $visibility . " METHOD $$method_decl_ref } // stmt2" . &ann(__FILE__, __LINE__) . $nl;
              &add_last($$va_method{'param-types'}, $last);
            }
          }
          else {
            &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, $max_width, __LINE__);
          }
        } else {
          &generate_va_generic_defn($va_method, $klass_path, $col, $klass_type, $max_width, __LINE__);
        }
        if (&is_decl) {
          if (&is_same_src_file($klass_ast) || &is_target()) { #rn2
              if (&num_kw_args($method)) {
                my $other_method_decl = &kw_args_method::type_decl($method);

                #my $scope = &ct($klass_path);
                $other_method_decl =~ s|\(\*($id)\)|$1|;
                my $visibility = '';
                if (&is_exported($method)) {
                  $visibility = ' [[export]]';
                }
                if ($$method{'inline?'}) {
                  #$$scratch_str_ref .= 'INLINE ';
                }
                $$scratch_str_ref .= $col . "$klass_type $klass_name" . $pad . " {" . $visibility . " METHOD $other_method_decl; } // stmt3" . &ann(__FILE__, __LINE__) . $nl;
              }
          }
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
  $$scratch_str_ref .= $col . "$klass_type @$klass_path {" . $visibility . " METHOD $$method_decl_ref }" . &ann(__FILE__, $line) . $nl;
}
sub generate_object_method_defn {
  my ($non_object_method, $klass_path, $col, $klass_type, $line) = @_;
  my $method = &convert_to_object_method($non_object_method);
  my $new_arg_type = $$method{'param-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'param-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  my $new_arg_list =  &arg_type::list_pair($new_arg_type, $new_arg_names);

  my $non_object_return_type = &arg::type($$non_object_method{'return-type'});
  my $return_type = &arg::type($$method{'return-type'});
  my $scratch_str_ref = &global_scratch_str_ref();
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = ' [[export]]';
  }
  my $method_name = &ct($$method{'name'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_path {" . $visibility . " INLINE METHOD $method_name($$new_arg_list) -> $return_type";

  my $new_unboxed_arg_names = &arg_type::names_unboxed($$non_object_method{'param-types'});
  my $new_unboxed_arg_names_list = &arg_type::list_names($new_unboxed_arg_names);

  if (&is_src_decl() || &is_target_decl()) {
    $$scratch_str_ref .= "; }" . &ann(__FILE__, $line) . $nl;
  } elsif (&is_target_defn()) {
    $$scratch_str_ref .= " {" . &ann(__FILE__, $line) . $nl;
    $col = &colin($col);

    if (defined $$method{'return-type'}) {
      if ($non_object_return_type ne $return_type) {
        $$scratch_str_ref .= $col . "$object_t result = box($method_name($$new_unboxed_arg_names_list));" . $nl;
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
    $$scratch_str_ref .= $col . "}} // @$klass_path\::$method_name" . $nl;
  }
}
sub convert_to_object_type {
  my ($type_seq) = @_;
  my $result = $type_seq;

  if (&is_box_type($type_seq)) {
    $result = $seq_object_t;
  }
  return $result;
}
sub convert_to_object_method {
  my ($non_object_method) = @_;
  my $method = &deep_copy($non_object_method);
  $$method{'return-type'} = &convert_to_object_type($$method{'return-type'});

  foreach my $param_type (@{$$method{'param-types'}}) {
    $param_type = &convert_to_object_type($param_type);
  }
  return $method;
}
sub typealias_slots_t {
  my ($klass_name) = @_;
  my $result = '';
  if ('object' ne $klass_name) {
    my $parts = [split(/::/, $klass_name)];
    if (1 < scalar @$parts) {
      my $basename = &remove_last($parts);
      my $inner_ns = join('::', @$parts);
      $result = "namespace $inner_ns { typealias $basename-t = $basename\::slots-t; }";
    } else {
      $result = "typealias $klass_name-t = $klass_name\::slots-t;";
    }
  }
  return $result;
}
# xor
# {'slots'}{'cat'} = aggregate struct|union|enum
# {'slots'}{'type'} = typealias type
#
# {'slots'}{'cat-info'} = aggregate items
sub generate_slots_decls {
  my ($ast, $col, $klass_path, $klass_name, $klass_ast) = @_;
  if (!$klass_ast) {
    $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  }
  my $scratch_str_ref = &global_scratch_str_ref();
  if (!&should_export_slots($klass_ast) && &has_slots_type($klass_ast)) {
    $$scratch_str_ref .= $col . "klass $klass_name {" . &slots_decl($$klass_ast{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    if (&is_same_src_file($klass_ast)) {
      $$scratch_str_ref .= $col .        &typealias_slots_t($klass_name) . $nl;
    } else {
      $$scratch_str_ref .= $col . '//' . &typealias_slots_t($klass_name) . $nl;
    }
  } elsif (!&should_export_slots($klass_ast) && &has_slots($klass_ast)) {
    my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
    if ($$struct_union_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "klass $klass_name {" . &slots_decl($$klass_ast{'slots'}) . '; }' . &ann(__FILE__, __LINE__) . $nl;
    } elsif ($$enum_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "klass $klass_name {";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_ast{'slots'}, $is_exported = 0, $is_slots = 1);
      $$scratch_str_ref .= $col . " }";
    } else {
      print STDERR &Dumper($$klass_ast{'slots'});
      die __FILE__, ":", __LINE__, ": error:" . $nl;
    }
    $$scratch_str_ref .= $col . '// ' . &typealias_slots_t($klass_name) . $nl;
  }
}
sub generate_exported_slots_decls {
  my ($ast, $col, $klass_path, $klass_name, $klass_ast, $max_width1, $max_width2) = @_;
  my $pad1 = '';
  if ($max_width1) {
    my $width = length($klass_name);
    $pad1 = ' ' x ($max_width1 - $width);
  }
  my $slots_decl = &slots_decl($$klass_ast{'slots'});
  my $typealias_slots_t = ' ' . &typealias_slots_t($klass_name);
  my $pad2 = '';
  if ($max_width2) {
    my $width = length($slots_decl);
    $pad2 = ' ' x ($max_width2 - $width);
  }
  if (!$klass_ast) {
    $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  }
  my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
  my $scratch_str_ref = &global_scratch_str_ref();
  if ('object' eq "$klass_name") {
    if ($$struct_union_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "klass $klass_name" . $pad1 . " {" . $slots_decl . '; }';
    } elsif ($$enum_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "//klass $klass_name" . $pad1 . " {" . $slots_decl . '; }';
    } else {
      print STDERR &Dumper($$klass_ast{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $pad2 . $typealias_slots_t . &ann(__FILE__, __LINE__) . $nl; # special-case
  } elsif (&should_export_slots($klass_ast) && &has_slots_type($klass_ast)) {
    $$scratch_str_ref .= $col . "klass $klass_name" . $pad1 . " {" . $slots_decl . '; }';
    my $excluded_types = { 'char16-t' => '__STDC_UTF_16__',
                           'char32-t' => '__STDC_UTF_32__',
                           'wchar-t'  => undef, # __WCHAR_MAX__, __WCHAR_TYPE__
                         };
    if (!exists $$excluded_types{"$klass_name-t"}) {
      $$scratch_str_ref .= $pad2 . $typealias_slots_t . &ann(__FILE__, __LINE__) . $nl;
    } else {
      $$scratch_str_ref .= &ann(__FILE__, __LINE__) . $nl;
    }
  } elsif (&should_export_slots($klass_ast) || (&has_slots($klass_ast) && &is_same_file($klass_ast))) {
    if ($$struct_union_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "klass $klass_name" . $pad1 . " {" . $slots_decl . '; }';
    } elsif ($$enum_set{$slots_cat}) {
      $$scratch_str_ref .= $col . "klass $klass_name" . $pad1 . " {";
      my $is_exported;
      my $is_slots;
      &generate_enum_decl(&colin($col), $$klass_ast{'slots'}, $is_exported = 1, $is_slots = 1);
      $$scratch_str_ref .= $col . " }";
    } else {
      print STDERR &Dumper($$klass_ast{'slots'});
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    $$scratch_str_ref .= $pad2 . $typealias_slots_t . &ann(__FILE__, __LINE__) . $nl;
  }
}
sub linkage_unit::generate_headers {
  my ($ast, $klass_names, $extra_dakota_headers) = @_;
  my $result = '';

  if (&is_decl()) {
    my $exported_headers = {};
    $$exported_headers{'<cassert>'}{'hardcoded-by-rnielsen'} = undef; # assert()
    $$exported_headers{'<cstdarg>'}{'hardcoded-by-rnielsen'} = undef; # va-list
    $$exported_headers{'<cstring>'}{'hardcoded-by-rnielsen'} = undef; # memcpy()

    my $all_headers = {};
    my $header_name;
    foreach my $header_names (values %{$$ast{'include-fors'}}) {
      foreach my $header_name (keys %$header_names) {
        $$all_headers{$header_name} = undef;
      }
    }
    foreach $header_name (keys %$exported_headers) {
      $$all_headers{$header_name} = undef;
    }
    foreach $header_name (sort keys %$all_headers) {
      $result .= "# include $header_name" . $nl;
    }
  }
  $result .= $extra_dakota_headers;
  return $result;
}
sub has_slots_type {
  my ($klass_ast) = @_;
  if (&has_slots($klass_ast) && &at($$klass_ast{'slots'}, 'type')) {
    return 1;
  }
  return 0;
}
sub has_slots_cat_info {
  my ($klass_ast) = @_;
  if (&has_slots($klass_ast) && &at($$klass_ast{'slots'}, 'cat-info')) {
    return 1;
  }
  return 0;
}
sub has_enum_info {
  my ($klass_ast) = @_;
  if (exists $$klass_ast{'enum'} && $$klass_ast{'enum'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_const_info {
  my ($klass_ast) = @_;
  if (exists $$klass_ast{'const'} && $$klass_ast{'const'}) {
    return 1;
  } else {
    return 0;
  }
}
sub has_enums {
  my ($klass_ast) = @_;
  if (exists $$klass_ast{'enum'} && $$klass_ast{'enum'} && 0 < scalar(@{$$klass_ast{'enum'}})) {
    return 1;
  } else {
    return 0;
  }
}
sub has_slots {
  my ($klass_ast) = @_;
  if (exists $$klass_ast{'slots'} && $$klass_ast{'slots'}) {
    return 1;
  }
  return 0;
}
sub has_slots_defn {
  my ($klass_ast) = @_;
  if (&has_slots($klass_ast)) {
    if (&at($$klass_ast{'slots'}, 'cat-info') ||
        &at($$klass_ast{'slots'}, 'type')) {
      return 1;
    }
  }
  return 0;
}
sub has_exported_slots {
  my ($klass_ast) = @_;
  if (&has_slots($klass_ast)) {
    return &is_exported($$klass_ast{'slots'});
  }
  return 0;
}
sub should_export_slots {
  my ($klass_ast) = @_;
  return (!$ENV{'DK_SRC_UNIQUE_HEADER'} && &has_slots($klass_ast)) || &has_exported_slots($klass_ast);
}
sub has_methods {
  my ($klass_ast) = @_;
  if (exists $$klass_ast{'methods'} && 0 != keys %{$$klass_ast{'methods'}}) {
    return 1;
  }
  return 0;
}
sub has_exported_methods {
  my ($klass_ast) = @_;
  if (&has_methods($klass_ast)) {
    if (exists $$klass_ast{'has-exported-behavior'} && defined $$klass_ast{'has-exported-behavior'}) {
      return $$klass_ast{'has-exported-behavior'};
    }
  }
  return 0;
}
sub order_klasses {
  my ($ast) = @_;
  my $type_aliases = {};
  my $depends = {};
  my $verbose = 0;
  my ($klass_name, $klass_ast);

  foreach my $klass_type_plural ('traits', 'klasses') {
    foreach $klass_name (sort keys %{$$ast{$klass_type_plural}}) {
      $klass_ast = $$ast{$klass_type_plural}{$klass_name};
      if (!$klass_ast || !$$klass_ast{'slots'}) {
        # if one has a klass scope locally (like adding a method on klass object)
        # dont use it since it won't have a slots defn
        $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
      }
      if ($klass_ast) {
        if (&has_slots($klass_ast)) {
          # even if not exported
          $$type_aliases{"$klass_name-t"} = "$klass_name\::slots-t";
          # hackhack
          my $slots_cat_info = &at($$klass_ast{'slots'}, 'cat-info');
          if ($slots_cat_info) {
            foreach my $slot_cat_info (@$slots_cat_info) {
              my $types = [values %$slot_cat_info];
              foreach my $type (@$types) {
                my $parts = {};
                &klass_part($type_aliases, $type, $parts);
                foreach my $type_klass_name (keys %$parts) {
                  if ($verbose) {
                    print STDERR "    $type\n      $type_klass_name" . $nl;
                  }
                  if (!exists $$ast{'klasses'}{$type_klass_name}) {
                    #$$ast{$klass_type_plural}{$type_klass_name}
                    #  = &generics::klass_ast_from_klass_name($type_klass_name);
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
    foreach $klass_name (sort keys %{$$ast{$klass_type_plural}}) {
      $klass_ast = $$ast{$klass_type_plural}{$klass_name};
      if (!$klass_ast || !$$klass_ast{'slots'}) {
        # if one has a klass scope locally (like adding a method on klass object)
        # dont use it since it won't have a slots defn
        $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
      }
      if ($klass_ast) {
        if ($verbose) {
          print STDERR "klass-name: $klass_name" . $nl;
        }
        my $slots_cat_info = &at($$klass_ast{'slots'}, 'cat-info');
        if (&has_slots($klass_ast)) {
          my $slots_type = &at($$klass_ast{'slots'}, 'type');
          if ($slots_type) {
            if ($verbose) {
              print STDERR "  type:" . $nl;
            }
            my $type = $slots_type; # silly
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
          } elsif ($slots_cat_info) {
            if ($verbose) {
              print STDERR "  info:" . $nl;
            }
            foreach my $slot_cat_info (@$slots_cat_info) {
              my $types = [values %$slot_cat_info];
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
sub linkage_unit::generate_klasses_funcs { # optionally inline
  my ($ast, $ordered_klass_names) = @_;
  my $col = '';
  my $klass_path = [];
  my $original_scratch_str_ref = &global_scratch_str_ref();
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-klass-funcs" . '-' . &suffix());
  foreach my $klass_name (sort @$ordered_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass_funcs_klass($ast, $col, $klass_path, $klass_name);
  }
  $$scratch_str_ref .= $nl;
  foreach my $klass_name (sort @$ordered_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass_funcs($ast, $col, $klass_path, $klass_name);
  }
  $$scratch_str_ref .= '//--box--' . $nl;
  foreach my $klass_name (sort @$ordered_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass_funcs_box($ast, $col, $klass_path, $klass_name);
  }
  &set_global_scratch_str_ref($original_scratch_str_ref);
  return $$scratch_str_ref;
}
sub linkage_unit::generate_klasses {
  my ($ast, $ordered_klass_names) = @_;
  my $col = '';
  my $klass_path = [];
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  my $max_width = 0;
  foreach my $klass_name (@$ordered_klass_names) {
    my $width = length($klass_name);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  &linkage_unit::generate_klasses_types_before($ast, $col, $klass_path, $ordered_klass_names);
  if (&is_decl()) {
    $$scratch_str_ref .=
      $nl .
      "# include <dakota-other.inc>" . $nl .
      $nl;
  }
  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-slots" . '-' . &suffix());
  &linkage_unit::generate_klasses_types_after($ast, $col, $klass_path, $ordered_klass_names);

  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-klass-vars" . '-' . &suffix());
  my $sorted_klass_names = [sort @$ordered_klass_names];
  my $num_lns = @$sorted_klass_names;
  while (my ($ln, $klass_name) = each @$sorted_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass_vars($ast, $col, $klass_path, $klass_name, $max_width, &should_ann($ln, $num_lns));
  }
  $$scratch_str_ref .= &labeled_src_str(undef, "klasses-klass-funcs-non-inline" . '-' . &suffix());
  while (my ($ln, $klass_name) = each @$sorted_klass_names) { # ok to sort
    &linkage_unit::generate_klasses_klass_funcs_non_inline($ast, $col, $klass_path, $klass_name, $max_width);
  }
  return $$scratch_str_ref;
}
sub linkage_unit::generate_klasses_types_before {
  my ($ast, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  if (&is_decl()) {
    my $max_width1 = 0;
    my $max_width2 = 0;
    foreach my $klass_name (@$ordered_klass_names) { # do not sort!
      my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);

      if (&should_export_slots($klass_ast) || (&has_slots($klass_ast) && &is_same_file($klass_ast))) {
        my $width1 = length($klass_name);
        if ($width1 > $max_width1) {
          $max_width1 = $width1;
        }
        my $width2 = length(&slots_decl($$klass_ast{'slots'}));
        if ($width2 > $max_width2) {
          $max_width2 = $width2;
        }
      }
    }
    foreach my $klass_name (@$ordered_klass_names) { # do not sort!
      my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);

      if (&should_export_slots($klass_ast) || (&has_slots($klass_ast) && &is_same_file($klass_ast))) {
        &generate_exported_slots_decls($ast, $col, $klass_path, $klass_name, $klass_ast, $max_width1, $max_width2);
      } else {
        &generate_slots_decls($ast, $col, $klass_path, $klass_name, $klass_ast);
      }
    }
  }
}
sub linkage_unit::generate_klasses_types_after {
  my ($ast, $col, $klass_path, $ordered_klass_names) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  foreach my $klass_name (@$ordered_klass_names) { # do not sort!
    my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
    my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
    my $is_exported;
    my $is_slots;

    if (&is_decl()) {
      if (&has_enums($klass_ast)) {
        foreach my $enum (@{$$klass_ast{'enum'} || []}) {
          if (&is_exported($enum)) {
            $$scratch_str_ref .= $col . "klass $klass_name {";
            &generate_enum_defn(&colin($col), $enum, $is_exported = 1, $is_slots = 0);
            $$scratch_str_ref .= $col . "} // $klass_name\::slots-t" . $nl;
          }
        }
      }
    }
    if (&has_slots_cat_info($klass_ast)) {
      if (&is_decl()) {
        if (&should_export_slots($klass_ast) || (&has_slots($klass_ast) && &is_same_file($klass_ast))) {
          $$scratch_str_ref .= $col . "klass $klass_name {";
          if ($$struct_union_set{$slots_cat}) {
            &generate_struct_or_union_defn(&colin($col), $$klass_ast{'slots'}, $is_exported = 1, $is_slots = 1);
          } elsif ($$enum_set{$slots_cat}) {
            &generate_enum_defn(&colin($col), $$klass_ast{'slots'}, $is_exported = 1, $is_slots = 1);
          } else {
            print STDERR &Dumper($$klass_ast{'slots'});
            die __FILE__, ":", __LINE__, ": error:\n";
          }
          $$scratch_str_ref .= $col . "} // $klass_name\::slots-t" . $nl;
        }
      } elsif (&is_src_defn() || &is_target_defn()) {
        if (!&should_export_slots($klass_ast)) {
          if (&is_exported($klass_ast)) {
            $$scratch_str_ref .= $col . "klass $klass_name {";
            if ($$struct_union_set{$slots_cat}) {
              &generate_struct_or_union_defn(&colin($col), $$klass_ast{'slots'}, $is_exported = 0, $is_slots = 1);
            } elsif ($$enum_set{$slots_cat}) {
              &generate_enum_defn(&colin($col), $$klass_ast{'slots'}, $is_exported = 0, $is_slots = 1);
            } else {
              print STDERR &Dumper($$klass_ast{'slots'});
              die __FILE__, ":", __LINE__, ": error:\n";
            }
            $$scratch_str_ref .= $col . "} // $klass_name\::slots-t" . $nl;
          } else {
            $$scratch_str_ref .= $col . "klass $klass_name {";
            if ($$struct_union_set{$slots_cat}) {
              &generate_struct_or_union_defn(&colin($col), $$klass_ast{'slots'}, $is_exported = 0, $is_slots = 1);
            } elsif ($$enum_set{$slots_cat}) {
              &generate_enum_decl(&colin($col), $$klass_ast{'slots'}, $is_exported = 0, $is_slots = 1);
            } else {
              print STDERR &Dumper($$klass_ast{'slots'});
              die __FILE__, ":", __LINE__, ": error:\n";
            }
            $$scratch_str_ref .= $col . "} // $klass_name\::slots-t" . $nl;
          }
        }
      }
    }
  }
}
sub linkage_unit::generate_klasses_klass_vars {
  my ($ast, $col, $klass_path, $klass_name, $max_width, $should_ann) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_body_vars($klass_ast, $col, $klass_type, $klass_path, $klass_name, $max_width, $should_ann);
  &path::remove_last($klass_path);
}
sub linkage_unit::generate_klasses_klass_funcs_klass {
  my ($ast, $col, $klass_path, $klass_name) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_body_funcs_klass($klass_ast, $col, $klass_type, $klass_path, $klass_name);
  &path::remove_last($klass_path);
}
sub linkage_unit::generate_klasses_klass_funcs_box {
  my ($ast, $col, $klass_path, $klass_name) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_body_funcs_box($klass_ast, $col, $klass_type, $klass_path, $klass_name);
  &path::remove_last($klass_path);
}
sub linkage_unit::generate_klasses_klass_funcs {
  my ($ast, $col, $klass_path, $klass_name) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_body_funcs($klass_ast, $col, $klass_type, $klass_path, $klass_name);
  &path::remove_last($klass_path);
}
sub linkage_unit::generate_klasses_klass_funcs_non_inline {
  my ($ast, $col, $klass_path, $klass_name, $max_width) = @_;
  my $klass_type = &generics::klass_type_from_klass_name($klass_name); # hackhack: name could be both a trait & a klass
  my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);
  &path::add_last($klass_path, $klass_name);
  my $scratch_str_ref = &global_scratch_str_ref();
  &linkage_unit::generate_klasses_body_funcs_non_inline($klass_ast, $col, $klass_type, $klass_path, $klass_name, $max_width);
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
  my $arg_type_list = &arg_type::list_types($$method{'param-types'});
  return "(*)($$arg_type_list) -> $return_type_str";
}
sub method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &arg_type::list_types($$method{'param-types'});
  my $name = &last($$method{'name'});
  return "(*$name)($$arg_type_list) -> $return_type";
}
sub kw_args_method::type {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'param-types'}, $$method{'kw-args'});
  return "(*)($$arg_type_list) -> $return_type";
}
sub kw_args_method::type_decl {
  my ($method) = @_;
  my $return_type = &arg::type($$method{'return-type'});
  my $arg_type_list = &kw_arg_type::list_types($$method{'param-types'}, $$method{'kw-args'});
  my $name = &last($$method{'name'});
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

    if (!$$method{'alias-dst'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'param-types'});
      my $generic_name = &ct($$method{'name'});
      if (&is_va($method)) {
        $result .= $col . "(cast(dkt-signature-func-t)cast(func $method_type)" . $pad . "__method-signature::va::$generic_name)()," . $nl;
      } else {
        $result .= $col . "(cast(dkt-signature-func-t)cast(func $method_type)" . $pad . "__method-signature::$generic_name)()," . $nl;
      }
      my $method_name = &ct($$method{'name'});
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
    if (!$$method{'alias-dst'}) {
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
    if (!$$method{'alias-dst'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'param-types'});
      my $generic_name = &ct($$method{'name'});
      my $in = &ident_comment($generic_name);
      if (&is_va($method)) {
        $result .= $col . "signature(va::$generic_name($$new_arg_type_list))," . $in . $nl;
      } else {
        $result .= $col . "signature($generic_name($$new_arg_type_list))," . $in . $nl;
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
    if (!$$method{'alias-dst'}) {
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
    if (!$$method{'alias-dst'}) {
      my $method_type = &method::type($method);
      my $width = length("cast(func $method_type)");
      my $pad = ' ' x ($max_width - $width);
      my $new_arg_type_list = &arg_type::list_types($$method{'param-types'});
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
    if (!$$method{'alias-dst'}) {
      my $generic_name = &ct($$method{'name'});
      my $new_arg_type_list = &arg_type::list_types($$method{'param-types'});
      my $return_type = &arg::type($$method{'return-type'});
      $result .=   $col . 'cast(method-t)dkt-null-method, ' . "// $generic_name($$new_arg_type_list) -> $return_type" . $nl;
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
    if ($$method{'alias-src'}) {
      my $new_arg_type_list = &arg_type::list_types($$method{'param-types'});
      my $generic_name = &ct($$method{'name'});
      foreach my $alias_name (@{$$method{'alias-src'}}) {
        if (&is_va($method)) {
          $result .= $col . "{ .alias-signature = signature(va::$alias_name($$new_arg_type_list)), .method-signature = signature(va::$generic_name($$new_arg_type_list)) }," . $nl;
        } else {
          $result .= $col . "{ .alias-signature = signature($alias_name($$new_arg_type_list)), .method-signature = signature($generic_name($$new_arg_type_list)) }," . $nl;
        }
      }
    }
    $method_num++;
  }
  $result .= $col . "{ .alias-signature = nullptr, .method-signature = nullptr }" . $nl;
  return $result;
}
sub export_pair {
  my ($symbol, $item) = @_;
  my $name = &ct($$item{'name'});
  my $type0 = &ct($$item{'param-types'}[0]);
  $type0 = ''; # hackhack
  my $lhs = "\"$symbol::$name($type0)\"";
  my $rhs = 1;
  return ($lhs, $rhs);
}
sub exported_methods {
  my ($klass_ast) = @_;
  my $exported_methods = {};
  {
    while (my ($key, $val) = each (%{$$klass_ast{'methods'}})) {
      if (&is_exported($val)) {
        $$exported_methods{$key} = $val;
      }
    }
  }
  return $exported_methods;
}
sub exported_slots_methods {
  my ($klass_ast) = @_;
  my $exported_slots_methods = {};
  {
    while (my ($key, $val) = each (%{$$klass_ast{'slots-methods'}})) {
      if (&is_exported($val)) {
        $$exported_slots_methods{$key} = $val;
      }
    }
  }
  return $exported_slots_methods;
}
sub dk_generate_cc_footer_klass {
  my ($klass_ast, $klass_name, $col, $klass_type, $symbols) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  #$$scratch_str_ref .= $col . "// generate_cc_footer_klass()" . $nl;

  my $token_registry = {};

  my $slot_type;
  my $slot_name;

  my $method_aliases = &klass::method_aliases($klass_ast);
  my $va_list_methods = &klass::va_list_methods($klass_ast);
  my $kw_arg_methods = &klass::kw_arg_methods($klass_ast);

  #my $num_va_methods = @$va_list_methods;

  #if (@$va_list_methods)
  #{
  #$$scratch_str_ref .= $col . "namespace va {" . $nl;
  #$col = &colin($col);
  ###
  if (@$va_list_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const signature-t* const[] __va-method-signatures = { // redundant" . &ann(__FILE__, __LINE__) . $nl;

    my $sorted_va_methods = [sort method::compare @$va_list_methods];

    $col = &colin($col);
    foreach my $va_method (@$sorted_va_methods) {
      if ($$va_method{'defined?'} || $$va_method{'alias-dst'}) {
        my $new_arg_type_list = &arg_type::list_types($$va_method{'param-types'});
        my $generic_name = &ct($$va_method{'name'});
        my $in = &ident_comment($generic_name);
        $$scratch_str_ref .= $col . "signature(va::$generic_name($$new_arg_type_list))," . $in . $nl;
        my $method_name;

        if ($$va_method{'alias-dst'}) {
          $method_name = &ct($$va_method{'alias-dst'});
        } else {
          $method_name = &ct($$va_method{'name'});
        }

        my $old_param_types = $$va_method{'param-types'};
        $$va_method{'param-types'} = &arg_type::var_args($$va_method{'param-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'param-types'} = $old_param_types;

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
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static var-args-method-t[] __var-args-method-addresses = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    ### todo: this looks like it might merge with address_body(). see die below
    my $sorted_va_methods = [sort method::compare @$va_list_methods];

    my $max_width = 0;
    foreach my $va_method (@$sorted_va_methods) {
      $va_method = &deep_copy($va_method);
      my $va_method_type = &method::type($va_method);
      my $width = length($va_method_type);
      if ($width > $max_width) {
        $max_width = $width;
      }
    }
    foreach my $va_method (@$sorted_va_methods) {
      $va_method = &deep_copy($va_method);
      my $va_method_type = &method::type($va_method);
      my $width = length($va_method_type);
      my $pad = ' ' x ($max_width - $width);

      if ($$va_method{'defined?'} || $$va_method{'alias-dst'}) {
        my $new_arg_names_list = &arg_type::list_types($$va_method{'param-types'});

        my $generic_name = &ct($$va_method{'name'});
        my $method_name;

        if ($$va_method{'alias-dst'}) {
          $method_name = &ct($$va_method{'alias-dst'});
        } else {
          $method_name = &ct($$va_method{'name'});
        }
        die if (!$$va_method{'defined?'} && !$$va_method{'alias-dst'} && !$$va_method{'generated?'});

        my $old_param_types = $$va_method{'param-types'};
        $$va_method{'param-types'} = &arg_type::var_args($$va_method{'param-types'});
        my $method_type = &method::type($va_method);
        $$va_method{'param-types'} = $old_param_types;

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
  if (@$kw_arg_methods) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const signature-t* const[] __kw-args-method-signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    #$$scratch_str_ref .= "\#if 0" . $nl;
    foreach my $kw_args_method (@$kw_arg_methods) {
      $kw_args_method = &deep_copy($kw_args_method);
      my $list_types = &arg_type::list_types($$kw_args_method{'param-types'});
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
  if (values %{$$klass_ast{'methods'} || []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const[] __method-signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &signature_body($klass_name, $$klass_ast{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  if (values %{$$klass_ast{'methods'} || []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-t[] __method-addresses = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &address_body($klass_name, $$klass_ast{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  my $num_method_aliases = scalar(@$method_aliases);
  if ($num_method_aliases) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static method-alias-t[] __method-aliases = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &alias_body($klass_name, $$klass_ast{'methods'}, &colin($col)) .
      $col . "};}" . $nl;
  }
  my $exported_methods =     &exported_methods($klass_ast);
  my $exported_slots_methods = &exported_slots_methods($klass_ast);

  if (values %{$exported_methods || []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const[] __exported-method-signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &signature_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}" . $nl .
      $col . "$klass_type @$klass_name { static method-t[] __exported-method-addresses = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &address_body($klass_name, $exported_methods, &colin($col)) .
      $col . "};}" . $nl;
  }
  if (values %{$exported_slots_methods || []}) {
    $$scratch_str_ref .=
      $col . "$klass_type @$klass_name { static const signature-t* const[] __exported-slots-method-signatures = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &slots_signature_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}" . $nl .
      $col . "$klass_type @$klass_name { static method-t[] __exported-slots-method-addresses = { //ro-data" . &ann(__FILE__, __LINE__) . $nl .
      $col . &address_body($klass_name, $exported_slots_methods, &colin($col)) .
      $col . "};}" . $nl;
  }
  ###
  ###
  ###
  #$$scratch_str_ref .= $nl;

  my $num_traits = @{( $$klass_ast{'traits'} || [] )}; # how to get around 'strict'
  if ($num_traits > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t[] __traits = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    my $trait_num = 0;
    for ($trait_num = 0; $trait_num < $num_traits; $trait_num++) {
      my $path = "$$klass_ast{'traits'}[$trait_num]";
      $$scratch_str_ref .= $col . "$path\::__name__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $num_requires = 0;
  if (exists $$klass_ast{'requires'} && defined $$klass_ast{'requires'}) {
    $num_requires = scalar @{$$klass_ast{'requires'}};
  }
  if ($num_requires > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t[] __requires = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    my $require_num = 0;
    for ($require_num = 0; $require_num < $num_requires; $require_num++) {
      my $path = "$$klass_ast{'requires'}[$require_num]";
      $$scratch_str_ref .= $col . "$path\::__name__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $num_provides = 0;
  if (exists $$klass_ast{'provides'} && defined $$klass_ast{'provides'}) {
    $num_provides = scalar @{$$klass_ast{'provides'}};
  }
  if ($num_provides > 0) {
    $$scratch_str_ref .= $nl;
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t[] __provides = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    my $provide_num = 0;
    for ($provide_num = 0; $provide_num < $num_provides; $provide_num++) {
      my $path = "$$klass_ast{'provides'}[$provide_num]";
      $$scratch_str_ref .= $col . "$path\::__name__," . $nl;
    }
    $$scratch_str_ref .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  while (my ($key, $val) = each(%{$$klass_ast{'imported-klasses'}})) {
    my $token;
    my $token_seq = $key;
    if (0 != length $token_seq) {
      my $path = $key;

      if (!$$token_registry{$path}) {
        $$token_registry{$path} = 1;
      }
    }
  }
  my $num_bound = keys %{$$klass_ast{'imported-klasses'}};
  if ($num_bound) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static symbol-t const[] __imported-klasses = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    while (my ($key, $val) = each(%{$$klass_ast{'imported-klasses'}})) {
      $$scratch_str_ref .= $col . "$key\::__name__," . $nl;
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
  my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
  if (&has_slots_cat_info($klass_ast)) {
    my $slots_cat_info = &at($$klass_ast{'slots'}, 'cat-info');
    my $root_name = '__slots-info';
    if ($$enum_set{$slots_cat}) {
      my $seq = [];
      my $prop_num = 0;
      foreach my $slot_cat_info (@$slots_cat_info) {
        my $tbl = {};
        $$tbl{'#name'} = "\#$$slot_cat_info{'name'}";
        if (defined $$slot_cat_info{'expr'}) {
          $$tbl{'#expr'} = "($$slot_cat_info{'expr'})";
          $$tbl{'#expr-str'} = "\"$$slot_cat_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_cat_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }" . $nl;
        &add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_target_runtime_info_seq($root_name, $seq, $col, __LINE__) . "}" . $nl;
    } else {
      my $seq = [];
      my $prop_num = 0;
      foreach my $slot_cat_info (@$slots_cat_info) {
        my $tbl = {};
        $$tbl{'#name'} = "\#$$slot_cat_info{'name'}";

        if ('struct' eq $slots_cat) {
          $$tbl{'#offset'} = "offsetof(slots-t, $$slot_cat_info{'name'})";
        }
        my $slot_name_ref = 'slots-t::' . $$slot_cat_info{'name'};
        $$tbl{'#size'} = 'sizeof(' . $slot_name_ref . ')';
        $$tbl{'#type'} = &as_literal_symbol($$slot_cat_info{'type'});
        $$tbl{'#typeid'} = 'INTERNED-DEMANGLED-TYPEID-NAME(' . $slot_name_ref . ')';

        if (defined $$slot_cat_info{'expr'}) {
          $$tbl{'#expr'} = "($$slot_cat_info{'expr'})";
          $$tbl{'#expr-str'} = "\"$$slot_cat_info{'expr'}\"";
        }
        my $prop_name = sprintf("%s-%s", $root_name, $$slot_cat_info{'name'});
        $$scratch_str_ref .=
          $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl($prop_name, $tbl, $col, $symbols, __LINE__) . " }" . $nl;
        &add_last($seq, "$prop_name");
        $prop_num++;
      }
      $$scratch_str_ref .=
        $col . "$klass_type @$klass_name { " . &generate_target_runtime_info_seq($root_name, $seq, $col, __LINE__) . " }" . $nl;
    }
  }
  if (&has_enum_info($klass_ast)) {
    my $num = 0;
    foreach my $enum (@{$$klass_ast{'enum'}}) {
      $$scratch_str_ref .= $col . "$klass_type @$klass_name { static enum-info-t __enum-info-$num\[] = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
      $col = &colin($col);

      my $slots_cat_info = $$enum{'cat-info'};
      foreach my $slot_cat_info (@$slots_cat_info) {
        my $name = $$slot_cat_info{'name'};
        if (defined $$slot_cat_info{'expr'}) {
          my $expr = $$slot_cat_info{'expr'};
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
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static named-enum-info-t[] __enum-info = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    $num = 0;
    foreach my $enum (@{$$klass_ast{'enum'}}) {
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
  if (&has_const_info($klass_ast)) {
    $$scratch_str_ref .= $col . "$klass_type @$klass_name { static const-info-t[] __const-info = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);

    foreach my $const (@{$$klass_ast{'const'}}) {
      my $value = join(' ', @{$$const{'rhs'}});
      $value =~ s/"/\\"/g;
      $$scratch_str_ref .= $col . "{ .name = \#$$const{'name'}, .type = \"$$const{'type'}\", .value = \"$value\" }," . $nl;
    }
    $$scratch_str_ref .= $col . "{ .name = nullptr, .type = nullptr, .value = nullptr }" . $nl;
    $col = &colout($col);
    $$scratch_str_ref .= $col . "};}" . $nl;
  }
  my $symbol = &ct($klass_name);
  $$tbbl{'#name'} = '__name__';
  $$tbbl{'#type'} = "\#$klass_type";

  if (&has_slots_type($klass_ast)) {
    my $slots_type = &at($$klass_ast{'slots'}, 'type');
    my $slots_type_ident = &dk_mangle($slots_type);
    $$tbbl{'#slots-type'} = &as_literal_symbol($slots_type);
    my $tp = 'slots-t';
   #$$tbbl{'#slots-typeid'} = 'dk-intern-free(dkt::demangle(typeid(' . $tp . ').name()))';
    $$tbbl{'#slots-typeid'} = 'INTERNED-DEMANGLED-TYPEID-NAME(' . $tp . ')';
  } elsif (&has_slots_cat_info($klass_ast)) {
    my $slots_cat = &at($$klass_ast{'slots'}, 'cat');
    $$tbbl{'#cat'} = "\#$slots_cat";
    $$tbbl{'#slots-info'} = '__slots-info';
  }
  my $slots_enum_base = &at($$klass_ast{'slots'}, 'enum-base');
  if ($slots_enum_base) {
    if (1 == scalar @$slots_enum_base) {
      $$tbbl{'#enum-base'} = '#' . $$slots_enum_base[0];
    } else {
      $$tbbl{'#enum-base'} = '#|' . join('', @$slots_enum_base) . '|';
    }
  }
  if (&has_slots_type($klass_ast) || &has_slots_cat_info($klass_ast)) {
    $$tbbl{'#size'} = 'sizeof(slots-t)';
  }
  if (&has_enum_info($klass_ast)) {
    $$tbbl{'#enum-info'} = '__enum-info';
  }
  if (&has_const_info($klass_ast)) {
    $$tbbl{'#const-info'} = '__const-info';
  }
  if (@$kw_arg_methods) {
    $$tbbl{'#kw-args-method-signatures'} = '__kw-args-method-signatures';
  }
  if (values %{$$klass_ast{'methods'}}) {
    $$tbbl{'#method-signatures'} = '__method-signatures';
    $$tbbl{'#method-addresses'} =  '__method-addresses';
  }
  if ($num_method_aliases) {
    $$tbbl{'#method-aliases'} = '&__method-aliases';
  }
  if (values %{$exported_methods || []}) {
    $$tbbl{'#exported-method-signatures'} = '__exported-method-signatures';
    $$tbbl{'#exported-method-addresses'} =  '__exported-method-addresses';
  }
  if (values %{$exported_slots_methods || []}) {
    $$tbbl{'#exported-slots-method-signatures'} = '__exported-slots-method-signatures';
    $$tbbl{'#exported-slots-method-addresses'} =  '__exported-slots-method-addresses';
  }
  if (@$va_list_methods) {
    $$tbbl{'#va-method-signatures'} =       '__va-method-signatures';
    $$tbbl{'#var-args-method-addresses'} =  '__var-args-method-addresses';
  }
  $token_seq = $$klass_ast{'interpose'};
  if ($token_seq) {
    my $path = $$klass_ast{'interpose'};
    $$tbbl{'#interpose-name'} = "$path\::__name__";
  }
  $token_seq = $$klass_ast{'superklass'};
  if ($token_seq) {
    my $path = $$klass_ast{'superklass'};
    $$tbbl{'#superklass-name'} = "$path\::__name__";
  }
  $token_seq = $$klass_ast{'klass'};
  if ($token_seq) {
    my $path = $$klass_ast{'klass'};
    $$tbbl{'#klass-name'} = "$path\::__name__";
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
  if (&is_exported($klass_ast)) {
    $$tbbl{'#is-exported'} = '1';
  }
  if (&has_exported_slots($klass_ast)) {
    $$tbbl{'#has-exported-state'} = '1';
  }
  if (&has_exported_methods($klass_ast)) {
    $$tbbl{'#has-exported-behavior'} = '1';
  }
  if ($$klass_ast{'has-initialize'}) {
    $$tbbl{'#initialize'} = 'cast(initialize-func-t)initialize';
  }
  if ($$klass_ast{'has-finalize'}) {
    $$tbbl{'#finalize'} = 'cast(finalize-func-t)finalize';
  }
  if ($$klass_ast{'module'}) {
    $$tbbl{'#module'} = "\#$$klass_ast{'module'}";
  }
  $$scratch_str_ref .=
    $col . "$klass_type @$klass_name { " . &generate_target_runtime_property_tbl('__klass-props', $tbbl, $col, $symbols, __LINE__) .
    $col . " }" . $nl;
  &add_last($global_klass_defns, "$symbol\::__klass-props");
  return $$scratch_str_ref;
}
sub generate_kw_arg_method_signature_decls {
  my ($methods, $klass_name, $col, $klass_type, $max_width) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if (&has_kw_args($method)) { # leave, don't change to num_kw_args()
      &generate_kw_args_method_signature_decl($method, $klass_name, $col, $klass_type, $max_width);
    }
  }
}
sub generate_kw_arg_method_signature_defns {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if (&has_kw_args($method)) { # leave, don't change to num_kw_args() (link errors)
      &generate_kw_args_method_signature_defn($method, $klass_name, $col, $klass_type);
    }
  }
}
sub generate_slots_method_signature_decls {
  my ($methods, $klass_name, $col, $klass_type, $max_width) = @_;
  foreach my $method (sort method::compare values %$methods) {
    &generate_slots_method_signature_decl($method, $klass_name, $col, $klass_type, $max_width);
  }
}
sub generate_slots_method_signature_defns {
  my ($methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    &generate_slots_method_signature_defn($method, $klass_name, $col, $klass_type);
  }
}
sub generate_kw_args_method_signature_decl {
  my ($method, $klass_name, $col, $klass_type, $max_width) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $width = length("@$klass_name");
  my $pad = ' ' x ($max_width - $width);
  my $return_type = &arg::type($$method{'return-type'});
  my $method_name = &ct($$method{'name'});
  my $list_types = &arg_type::list_types($$method{'param-types'});
 #my $kw_list_types = &method::kw_list_types($method);
  $$scratch_str_ref .= $col . "$klass_type @$klass_name" . $pad . " { namespace __method-signature { namespace va { func $method_name($$list_types) -> const signature-t*; }}} //kw-args-method-signature" . &ann(__FILE__, __LINE__) . $nl;
}
sub generate_kw_args_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'param-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { namespace va { func $method_name($$list_types) -> const signature-t* { //kw-args-method-signature" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $kw_list_types = &method::kw_list_types($method);
 #$kw_list_types = &remove_extra_whitespace($kw_list_types);
  if (1) { # optional?
    my $defs = [];
    foreach my $kw_args (@{$$method{'kw-args'}}) {
      if (defined $$kw_args{'default'}) {
        my $def = $$kw_args{'default'};
        $def =~ s/"/\\"/g;
        &add_last($defs, $def);
      }
    }
    my $kw_arg_default_placeholder = $$kw_arg_placeholders{'default'};
    foreach my $def (@$defs) {
      my $count = $kw_list_types =~ s/$kw_arg_default_placeholder/ $def/; # extra whitespace
      die if 1 != $count;
    }
  }
  my $padlen = length($col);
  $padlen += length("static const signature-t result = { ");
  my $kw_arg_list = "static const signature-t result = { .name =        \"$method_name\"," . $nl .
    (' ' x $padlen) . ".param-types = \"$kw_list_types\"," . $nl .
    (' ' x $padlen) . ".return-type = \"$return_type\" };" . $nl;
  $$scratch_str_ref .=
    $col . "$kw_arg_list" . $nl .
    $col . "return &result;" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}}} // @$klass_name\::__method-signature\::va\::$method_name()" . $nl;
}
sub generate_slots_method_signature_decl {
  my ($method, $klass_name, $col, $klass_type, $max_width) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $width = length("@$klass_name");
  my $pad = ' ' x ($max_width - $width);
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'param-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name" . $pad . " { namespace __method-signature { func $method_name($$list_types) -> const signature-t*; }} //slots-method-signature" . &ann(__FILE__, __LINE__) . $nl;
}
sub generate_slots_method_signature_defn {
  my ($method, $klass_name, $col, $klass_type) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  my $method_name = &ct($$method{'name'});
  my $return_type = &arg::type($$method{'return-type'});
  my $list_types = &arg_type::list_types($$method{'param-types'});
  $$scratch_str_ref .= $col . "$klass_type @$klass_name { namespace __method-signature { func $method_name($$list_types) -> const signature-t* { //slots-method-signature" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  my $method_list_types = &method::list_types($method);
  $method_list_types = &remove_extra_whitespace($method_list_types);
  my $padlen = length($col);
  $padlen += length("static const signature-t result = { ");
  my $arg_list =    "static const signature-t result = { .name =        \"$method_name\"," . $nl .
    (' ' x $padlen) . ".param-types = \"$method_list_types\"," . $nl .
    (' ' x $padlen) . ".return-type = \"$return_type\" };";
  $$scratch_str_ref .=
    $col . "$arg_list" . $nl .
    $col . "return &result;" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}} // @$klass_name\::__method-signature\::$method_name()" . $nl;
}
sub generate_kw_arg_method_defns {
  my ($slots, $methods, $klass_name, $col, $klass_type) = @_;
  foreach my $method (sort method::compare values %$methods) {
    if (&has_kw_args($method)) { # leave, don't change to num_kw_args() (link errors)
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
  my $new_arg_type = $$method{'param-types'};
  my $new_arg_type_list = &arg_type::list_types($new_arg_type);
  $new_arg_type = $$method{'param-types'};
  my $new_arg_names = &arg_type::names($new_arg_type);
  &replace_first($new_arg_names, 'self');
  &replace_last($new_arg_names, '_args_');
  my $new_arg_list =  &arg_type::list_pair($new_arg_type, $new_arg_names);
  my $return_type = &arg::type($$method{'return-type'});
  my $visibility = '';
  if (&is_exported($method)) {
    $visibility = ' [[export]]';
  }
  my $func_spec = '';
  #if ($$method{'inline?'})
  #{
  #    $func_spec = 'INLINE ';
  #}
  my $method_name = &ct($$method{'name'});
  my $method_type_decl;
  my $list_types = &arg_type::list_types($$method{'param-types'});
  my $list_names = &arg_type::list_names($$method{'param-types'});

  $$scratch_str_ref .=
    "$klass_type @$klass_name { namespace va {" . $visibility . $func_spec . " METHOD $method_name($$new_arg_list) -> $return_type { //kw-args" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);

  $$scratch_str_ref .=
    $col . "static const signature-t* __method-signature__ = KW-ARGS-METHOD-SIGNATURE(va::$method_name($$list_types)); USE(__method-signature__);" . $nl;

  $$method{'name'} = ['_func_'];
  my $func_name = &ct($$method{'name'});

  #$$scratch_str_ref .=
  #  $col . "static const signature-t* __method-signature__ = KW-ARGS-METHOD-SIGNATURE(va::$method_name($$list_types)); USE(__method-signature__);" . $nl;

  my $arg_names = &deep_copy(&arg_type::names(&deep_copy($$method{'param-types'})));
  my $arg_names_list = &arg_type::list_names($arg_names);

  if (&num_kw_args($method)) {
    #my $param = &remove_last($$method{'param-types'}); # remove intptr-t type
    $method_type_decl = &kw_args_method::type_decl($method);
    #&add_last($$method{'param-types'}, $param);
  } else {
    my $param1 = &remove_last($$method{'param-types'}); # remove va-list-t type
    # should test $param1
    #my $param2 = &remove_last($$method{'param-types'}); # remove intptr-t type
    ## should test $param2
    $method_type_decl = &method::type_decl($method);
    #&add_last($$method{'param-types'}, $param2);
    &add_last($$method{'param-types'}, $param1);
  }
  if (&num_kw_args($method)) {
    $$scratch_str_ref .= $col;
    my $delim = '';
    foreach my $kw_arg (@{$$method{'kw-args'}}) {
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
    foreach my $kw_arg (@{$$method{'kw-args'}}) {
      my $kw_arg_name = $$kw_arg{'name'};
      $$scratch_str_ref .= " bool-t $kw_arg_name;";
      $initializer .= "${delim}false";
      $delim = ', ';
    }
    $$scratch_str_ref .= " } _state_ = { $initializer };" . $nl;
  }
  #$$scratch_str_ref .= $col . "if (nullptr != $$new_arg_names[-1]) {" . $nl;
  #$col = &colin($col);
  $$scratch_str_ref .=
    $col . "const $keyword_t* _keyword_;" . $nl .
    $col . "while ((_keyword_ = va-arg(_args_, decltype(_keyword_))) != SENTINEL-PTR) {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  $$scratch_str_ref .= $col . "switch (_keyword_->hash) { // hash is a constexpr. its compile-time evaluated." . $nl;
  $col = &colin($col);

  foreach my $kw_arg (@{$$method{'kw-args'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    my $kw_arg_type = &arg::type($$kw_arg{'type'});
    $$scratch_str_ref .= $col . "case \#$kw_arg_name: // dk-hash() is a constexpr. its compile-time evaluated." . $nl;
    #$$scratch_str_ref .= $col . "{" . $nl;
    $col = &colin($col);
    $$scratch_str_ref .=
      $col . "assert(_keyword_->symbol == \#$kw_arg_name);" . $nl .
      $col . "$kw_arg_name = cast(decltype($kw_arg_name))va-arg($$new_arg_names[-1], intptr-t);" . $nl .
      $col . "_state_.$kw_arg_name = true;" . $nl .
      $col . "break;" . $nl;
    $col = &colout($col);
    #$$scratch_str_ref .= $col . "}" . $nl;
  }
  $$scratch_str_ref .= $col . "default:" . $nl;
  #$$scratch_str_ref .= $col . "{" . $nl;
  $col = &colin($col);
  $$scratch_str_ref .=
    $col . "throw \$make(no-such-keyword-exception::klass()," . $nl .
    $col . "            \#object$colon    self," . $nl .
    $col . "            \#signature$colon __method-signature__," . $nl .
    $col . "            \#keyword$colon   _keyword_->symbol);" . $nl;
  $col = &colout($col);
  #$$scratch_str_ref .= $col . "}" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}" . $nl;
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}" . $nl;

  foreach my $kw_arg (@{$$method{'kw-args'}}) {
    my $kw_arg_type =  &arg::type($$kw_arg{'type'});
    my $kw_arg_name =    $$kw_arg{'name'};
    $$scratch_str_ref .= $col . "unless (_state_.$kw_arg_name)" . $nl;
    $col = &colin($col);
    if (defined $$kw_arg{'default'}) {
      my $kw_arg_default = $$kw_arg{'default'};
      if ('nullptr' eq $kw_arg_default) {
        $$scratch_str_ref .= $col . "$kw_arg_name = $kw_arg_default;" . $nl;
      } elsif ($kw_arg_type =~ /\[\]$/ && $kw_arg_default =~ /^\{/) {
        $$scratch_str_ref .= $col . "$kw_arg_name = cast($kw_arg_type)$kw_arg_default;" . $nl;
      } else {
        $$scratch_str_ref .= $col . "$kw_arg_name = cast(decltype($kw_arg_name))$kw_arg_default;" . $nl;
      }
    } else {
      $$scratch_str_ref .=
        $col . "throw \$make(missing-keyword-exception::klass()," . $nl .
        $col . "            \#object$colon    self," . $nl .
        $col . "            \#signature$colon __method-signature__," . $nl .
        $col . "            \#keyword$colon   \#$kw_arg_name);" . $nl;
    }
    $col = &colout($col);
  }
  my $delim = '';
  #my $last_arg_name = &remove_last($new_arg_names); # remove name associated with intptr-t type
  my $args = '';

  for (my $i = 0; $i < @$new_arg_names - 1; $i++) {
    $args .= "$delim$$new_arg_names[$i]";
    $delim = ', ';
  }
  #&add_last($new_arg_names, $last_arg_name); # add name associated with intptr-t type
  foreach my $kw_arg (@{$$method{'kw-args'}}) {
    my $kw_arg_name = $$kw_arg{'name'};
    $args .= ", $kw_arg_name";
  }
  $$scratch_str_ref .= $col . "static func $method_type_decl = $qualified_klass_name\::$method_name; //qualqual" . $nl;
  if ($$method{'return-type'}) {
    $$scratch_str_ref .=
      $col . "auto _result_ = $func_name($args);" . $nl .
      $col . "return _result_;" . $nl;
  } else {
    $$scratch_str_ref .=
      $col . "$func_name($args);" . $nl .
      $col . "return;" . $nl;
  }
  $col = &colout($col);
  $$scratch_str_ref .= $col . "}}} // @$klass_name\::va\::$method_name()" . $nl;
  #&path::remove_last($klass_name);
}
sub dk_generate_cc_footer {
  my ($ast) = @_;
  my $stack = [];
  my $col = '';
  my $scratch_str = ''; &set_global_scratch_str_ref(\$scratch_str);
  my $scratch_str_ref = &global_scratch_str_ref();
  &dk_generate_kw_arg_method_defns($ast, $stack, 'trait', $col);
  &dk_generate_kw_arg_method_defns($ast, $stack, 'klass', $col);

  if (&is_target_defn()) {
    my $num_klasses = scalar @$global_klass_defns;
    if (0 == $num_klasses) {
      $$scratch_str_ref .= $nl;
      $$scratch_str_ref .= $col . "static named-info-t* klass-defns = nullptr;" . $nl;
    } else {
      $$scratch_str_ref .= &generate_target_runtime_info_seq('klass-defns', [sort @$global_klass_defns], $col, __LINE__);
    }
    if (0 == keys %{$$ast{'interposers'}}) {
      $$scratch_str_ref .= $nl;
      $$scratch_str_ref .= $col . "static property-t* interposers = nullptr;" . &ann(__FILE__, __LINE__) . $nl;
    } else {
      #print STDERR Dumper $$ast{'interposers'};
      my $interposers = &many_1_to_1_from_1_to_many($$ast{'interposers'});
      #print STDERR Dumper $interposers;

      $$scratch_str_ref .= $col . "static property-t[] interposers = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
      $col = &colin($col);
      my ($key, $val);
      my $num_klasses = scalar keys %$interposers;
      foreach $key (sort keys %$interposers) {
        $val = $$interposers{$key};
        $$scratch_str_ref .= $col . "{ .key = $key\::__name__, .item = cast(intptr-t)$val\::__name__ }," . $nl;
      }
      $$scratch_str_ref .= $col . "{ .key = nullptr, .item = cast(intptr-t)nullptr }" . $nl;
      $col = &colout($col);
      $$scratch_str_ref .= $col . "};" . $nl;
    }
  }
  return $$scratch_str_ref;
}
sub dk_generate_kw_arg_method_defns {
  my ($ast, $stack, $klass_type, $col) = @_;
  my $scratch_str_ref = &global_scratch_str_ref();
  while (my ($klass_name, $klass_ast) = each(%{$$ast{$$plural_from_singular{$klass_type}}})) {
    if ($klass_ast && 0 < keys(%$klass_ast)) { #print STDERR &Dumper($klass_ast);
      &path::add_last($stack, $klass_name);
      if (&is_target_defn()) {
        &dk_generate_cc_footer_klass($klass_ast, $stack, $col, $klass_type, $$ast{'symbols'});
      } else {
        &generate_kw_arg_method_signature_defns($$klass_ast{'methods'}, [ $klass_name ], $col, $klass_type);
        &generate_kw_arg_method_defns($$klass_ast{'slots'}, $$klass_ast{'methods'}, [ $klass_name ], $col, $klass_type);
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
    foreach my $item (@$subseq) {
      my $rhs = $item;
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
  $result = 1 if !($ln % $adjusted_ann_interval);
  return $result;
}
sub almost_symbol {
  my ($ident) = @_;
  if (1) {
    $ident =~ s/^(_*)//;
    my $leading = $1;
    $ident =~ s/(_*)$//;
    my $trailing = $1;
    $ident =~ s/(\w)_(\w)/$1-$2/g;
    $ident = $leading . $ident . $trailing;
  }
  return $ident;
}
sub linkage_unit::generate_symbols {
  my ($ast, $symbols) = @_;
  my $col = '';

  my $scratch_str = '';
  if (&is_target_defn()) {
    $scratch_str .=
      $col . "static func __initial-prolog() -> void { dkt-register-info(nullptr); }" . $nl .
      $col . "static func __final-prolog()   -> void { dkt-deregister-info(nullptr); }" . $nl .
      $col . "static __ddl-t __ddl-prolog = __ddl-t{__initial-prolog, __final-prolog};" . &ann(__FILE__, __LINE__) . $nl .
      $nl;
  }
  while (my ($symbol, $symbol_seq) = each(%$symbols)) {
    my $ident_symbol = &dk_mangle_seq($symbol_seq);
    $$symbols{$symbol} = $ident_symbol;
  }
  foreach my $symbol (keys %{$$ast{'symbols'}}) {
    &add_symbol_to_ident_symbol($$ast{'symbols'}, $symbols, $symbol);
  }
  foreach my $klass_type ('klasses', 'traits') {
    foreach my $symbol (keys %{$$ast{$klass_type}}) {
      &add_symbol_to_ident_symbol($$ast{'symbols'}, $symbols, $$ast{$klass_type}{$symbol}{'module'});

      if (!exists $$symbols{$symbol}) {
        &add_symbol_to_ident_symbol($$ast{'symbols'}, $symbols, $symbol);
      }
      my $slots = "$symbol\::slots-t";

      if (!exists $$symbols{$slots}) {
        #&add_symbol_to_ident_symbol($$ast{'symbols'}, $symbols, $slots);
      }
      my $klass_typealias = "$symbol-t";

      if (!exists $$symbols{$klass_typealias}) {
        &add_symbol_to_ident_symbol($$ast{'symbols'}, $symbols, $klass_typealias);
      }
    }
  }
  my $symbol_keys = [sort symbol::compare keys %$symbols];
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
  my $sorted_symbol_keys = [sort @$symbol_keys];
  while (my ($ln, $symbol) = each @$sorted_symbol_keys) {
    $symbol =~ s/^#//;
    my $ident = &dk_mangle($symbol);
    $ident = &almost_symbol($ident);
    my $width = length($ident);
    my $pad = ' ' x ($max_width - $width);
    my $should_ann = &should_ann($ln, $num_lns);
    if (&is_src_decl() || &is_target_decl()) {
      $scratch_str .= $col . "extern symbol-t $ident;" . $pad . ' // ' . &as_literal_symbol($symbol) . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
    } elsif (&is_target_defn()) {
      $symbol =~ s|"|\\"|g;
      $symbol =~ s/\\\|/\|/g;
      $scratch_str .= $col . "symbol-t $ident =" . $pad . " dk-intern(\"$symbol\");" . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  return $scratch_str;
}
sub ident_comment {
  my ($ident, $only_if_symbol) = @_;
  my $result = '';
  if (&needs_hex_encoding($ident)) {
    if (!$only_if_symbol) {
      $result = ' // ' . $ident;
    } elsif ($only_if_symbol && $ident =~ m/^#/) {
      $result = ' // ' . $ident;
    }
  }
  return $result;
}
sub linkage_unit::generate_keywords {
  my ($ast) = @_;
  my $col = '';

  my ($symbol, $symbol_seq);
  my $symbol_keys = [sort symbol::compare keys %{$$ast{'keywords'}}];
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
    $ident = &almost_symbol($ident);
    my $width = length($ident);
    my $pad = ' ' x ($max_width - $width);
    if (defined $ident) {
      my $should_ann = &should_ann($ln, $num_lns);
      if (&is_decl()) {
        $scratch_str .= $col . "extern const $keyword_t $ident;" . $pad . ' // ' . &as_literal_symbol($symbol) . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
      } else {
        my $in = &ident_comment($symbol);
        # keyword-defn
        $scratch_str .= $col . "const $keyword_t $ident =" . $pad . " { dk-hash(\"$symbol\")," . $pad . " #$symbol };" . $in . &ann(__FILE__, __LINE__, !$should_ann) . $nl;
      }
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . '}' . &ann(__FILE__, __LINE__) . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_strs {
  my ($ast) = @_;
  my $scratch_str = "";
  my $col = '';
  $scratch_str .= $col . "namespace __literal::__str {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  foreach my $str (sort keys %{$$ast{'literal-strs'}}) {
    my $str_ident = &dk_mangle($str);
    if (&is_decl()) {
      $scratch_str .= $col . "extern $object_t $str_ident; // \"$str\"" . $nl;
    } else {
      $scratch_str .= $col . "$object_t $str_ident = nullptr; // \"$str\"" . $nl;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . "}" . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_strs_seq {
  my ($target_srcs_ast) = @_;
  my $scratch_str = "";
  my $col = '';
  if (0 == scalar keys %{$$target_srcs_ast{'literal-strs'}}) {
    $scratch_str .= $col . "//static str-t const[] __str-literals = { nullptr }; //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $scratch_str .= $col . "//static $object_t*[] __str-ptrs = { nullptr }; //rw-data" . &ann(__FILE__, __LINE__) . $nl;
  } else {
    $scratch_str .= $col . "static str-t const[] __str-literals = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$target_srcs_ast{'literal-strs'}}) {
      $scratch_str .= $col . "#|$str|," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static symbol-t[] __str-names = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$target_srcs_ast{'literal-strs'}}) {
      $scratch_str .= $col . "#|$str|," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static assoc-node-t[] __str-ptrs = { //rw-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $str (sort keys %{$$target_srcs_ast{'literal-strs'}}) {
      my $str_ident = &dk_mangle($str);
      $scratch_str .= $col . "{ .next = nullptr, .item = cast(intptr-t)&__literal::__str::$str_ident }," . $nl;
    }
    $scratch_str .= $col . "{ .next = nullptr, .item = cast(intptr-t)nullptr }" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub linkage_unit::generate_ints {
  my ($ast) = @_;
  my $scratch_str = "";
  my $col = '';
  $scratch_str .= $col . "namespace __literal::__int {" . &ann(__FILE__, __LINE__) . $nl;
  $col = &colin($col);
  foreach my $int (sort keys %{$$ast{'literal-ints'}}) {
    my $int_ident = &dk_mangle($int);
    if (&is_decl()) {
      $scratch_str .= $col . "extern $object_t $int_ident;" . $nl;
    } else {
      $scratch_str .= $col . "$object_t $int_ident = nullptr;" . $nl;
    }
  }
  $col = &colout($col);
  $scratch_str .= $col . "}" . $nl;
  return $scratch_str;
}
sub linkage_unit::generate_target_runtime_ints_seq {
  my ($target_srcs_ast) = @_;
  my $scratch_str = "";
  my $col = '';
  if (0 == scalar keys %{$$target_srcs_ast{'literal-ints'}}) {
    $scratch_str .= $col . "//static intmax-t const[] __int-literals = { 0 }; //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $scratch_str .= $col . "//static $object_t*[] __int-ptrs = { nullptr }; //rw-data" . &ann(__FILE__, __LINE__) . $nl;
  } else {
    $scratch_str .= $col . "static intmax-t const[] __int-literals = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$target_srcs_ast{'literal-ints'}}) {
      $scratch_str .= $col . "$int," . $nl;
    }
    $scratch_str .= $col . "0 // nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static symbol-t[] __int-names = { //ro-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$target_srcs_ast{'literal-ints'}}) {
      my $ident = &dk_mangle($int);
      $scratch_str .= $col . "__symbol::$ident," . $nl;
    }
    $scratch_str .= $col . "nullptr" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;

    $scratch_str .= $col . "static assoc-node-t[] __int-ptrs = { //rw-data" . &ann(__FILE__, __LINE__) . $nl;
    $col = &colin($col);
    foreach my $int (sort keys %{$$target_srcs_ast{'literal-ints'}}) {
      my $int_ident = &dk_mangle($int);
      $scratch_str .= $col . "{ .next = nullptr, .item = cast(intmax-t)&__literal::__int::$int_ident }," . $nl;
    }
    $scratch_str .= $col . "{ .next = nullptr, .item = cast(intmax-t)nullptr }" . $nl;
    $col = &colout($col);
    $scratch_str .= $col . "};" . $nl;
  }
  return $scratch_str;
}
sub generate_target_runtime_property_tbl {
  my ($name, $tbl, $col, $symbols, $line) = @_;
  #print STDERR &Dumper($tbl);
  my $sorted_keys = [sort keys %$tbl];
  my $result = '';
  my $max_key_width = 0;
  my $num = 1;
  foreach my $key (@$sorted_keys) {
    my $item = $$tbl{$key};

    if ('HASH' eq ref $item) {
      $result .= &generate_target_runtime_info("$name-$num", $item, $col, $symbols, $line);
      $item = "&$name-$num";
      $num++;
    } elsif (!defined $item) {
      $item = "nullptr";
    }
    my $key_width = length($key);
    if ($key_width > $max_key_width) {
      $max_key_width = $key_width;
    }
  }
  $result .= "static property-t\[\] $name = { //ro-data" . &ann(__FILE__, $line) . $nl;
  $col = &colin($col);
  $num = 1;
  foreach my $key (@$sorted_keys) {
    my $item = $$tbl{$key};

    if ('HASH' eq ref $item) {
      $item = "&$name-$num";
      $num++;
    } elsif (!defined $item) {
      $item = "nullptr";
    }
    my $key_width = length($key);
    my $pad = ' ' x ($max_key_width - $key_width);

    if ($item =~ /^"(.*)"$/) {
      my $literal_symbol = &as_literal_symbol($1);
      if ($$symbols{$literal_symbol}) {
        $item = $literal_symbol;
      } else {
        $item = "dk-intern($item)";
      }
    }
    my $in1 = &ident_comment($key, 1);
    my $in2 = &ident_comment($item, 1);
    $result .= $col . "{ .key = $key," . $pad . " .item = cast(intptr-t)$item }," . $in1 . $in2 . $nl;
  }
  $col = &colout($col);
  $result .= $col . "};";
  return $result;
}
sub generate_target_runtime_info {
  my ($name, $tbl, $col, $symbols, $line) = @_;
  my $result = &generate_target_runtime_property_tbl("$name-props", $tbl, $col, $symbols, $line);
  $result .= $nl;
  $result .= $col . "static named-info-t $name = { .next = nullptr, .count = countof($name-props), .items = $name-props };" . &ann(__FILE__, $line) . $nl;
  return $result;
}
sub generate_target_runtime_info_seq {
  my ($name, $seq, $col, $line) = @_;
  my $result = '';

  $result .= $col . "static named-info-t[] $name = { //rw-data (.next)" . &ann(__FILE__, $line) . $nl;
  $col = &colin($col);

  my $max_width = 0;
  foreach my $item (@$seq) {
    my $width = length($item);
    if ($width > $max_width) {
      $max_width = $width;
    }
  }
  foreach my $item (@$seq) {
    my $width = length($item);
    my $pad = ' ' x ($max_width - $width);
    $result .= $col . "{ .next = nullptr, .count = countof($item)," . $pad . " .items = $item }," . $nl;
  }
  $result .= $col . "{ .next = nullptr, .count = 0, .items = nullptr }" . $nl;
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
  my ($file, $path_name, $target_inputs_ast) = @_;
  my ($dir, $file_basename) = &split_path($file);
  my $filestr = &filestr_from_file($file);
  my $output = $path_name =~ s/\.dk$/\.$cc_ext/r;
  $output =~ s|^\./||;
  if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
    $output = $ENV{'DKT_DIR'} . '/' . $output
  }
  my $remove;

  if ($ENV{'DK_NO_LINE'}) {
    &write_to_file_converted_strings("$output", [ $filestr ], $remove = 1, $target_inputs_ast);
  } else {
    if ($ENV{'DK_ABS_PATH'}) {
      my $cwd = &getcwd();
      &write_to_file_converted_strings("$output", [ "# line 1 \"$cwd/$file_basename\"" . &ann(__FILE__, __LINE__) . $nl,
                                                    $filestr ],
                                       $remove = 1, $target_inputs_ast);
    } else {
      &write_to_file_converted_strings("$output", [ "# line 1 \"$file_basename\"" . &ann(__FILE__, __LINE__) . $nl,
                                                    $filestr ],
                                       $remove = 1, $target_inputs_ast);
    }
  }
}
sub start {
  my ($argv) = @_;
  foreach my $in_path (@$argv) {
    my $filestr = &filestr_from_file($in_path);
    my $path;
    my $remove;
    my $target_inputs_ast;
    &write_to_file_converted_strings($path = undef, [ $filestr ], $remove = undef, $target_inputs_ast = undef);
  }
}
unless (caller) {
  &start(\@ARGV);
}
1;
