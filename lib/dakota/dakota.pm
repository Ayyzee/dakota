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

package dakota::dakota;

use strict;
use warnings;
use Fcntl qw(:DEFAULT :flock);
use sort 'stable';

my $gbl_prefix;
my $gbl_compiler;
my $extra;
my $builddir;
my $h_ext;
my $cc_ext;
my $o_ext;
my $so_ext;
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
  use dakota::util;
  use dakota::parse;
  use dakota::generate;
  $gbl_compiler = &do_json("$gbl_prefix/lib/dakota/compiler/command-line.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/compiler/command-line.json\") failed: $!\n";
  my $platform = &do_json("$gbl_prefix/lib/dakota/platform.json")
    or die "&do_json($gbl_prefix/lib/dakota/platform.json) failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $extra = &do_json("$gbl_prefix/lib/dakota/extra.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/extra.json\") failed: $!\n";
  $h_ext = &var($gbl_compiler, 'h_ext', 'h');
  $cc_ext = &var($gbl_compiler, 'cc_ext', 'cc');
  $o_ext =  &var($gbl_compiler, 'o_ext',  'o');
  $so_ext = &var($gbl_compiler, 'so_ext', 'so'); # default dynamic shared object/library extension
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 is_o_path
                 target_cc_path
                 rel_target_h_path
                 target_klass_func_decls_path
                 target_klass_func_defns_path
                 target_generic_func_decls_path
                 target_generic_func_defns_path
             );

use Data::Dumper;
$Data::Dumper::Terse =     1;
$Data::Dumper::Deepcopy =  1;
$Data::Dumper::Purity =    1;
$Data::Dumper::Useqq =     1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent =    1;   # default = 2

undef $/;

my $should_replace_library_path_with_lib_opts = 1;
my $should_write_ctlg_files = 1;
my $want_separate_ast_pass = 1; # currently required to bootstrap dakota
my $want_separate_precompile_pass = 0;
my $show_outfile_info = 0;
my $global_should_echo = 0;
my $exit_status = 0;
my $dk_exe_type = undef;

my $cxx_compile_flags = &var($gbl_compiler, 'CXX_COMPILE_FLAGS', [ '--compile', '--PIC' ]); # or -fPIC
my $cxx_shared_flags =  &var($gbl_compiler, 'CXX_SHARED_FLAGS',  '--shared');
my $cxx_dynamic_flags = &var($gbl_compiler, 'CXX_DYNAMIC_FLAGS', '--dynamic');

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &ident_regex();
my $msig_type = &method_sig_type_regex();
my $msig = &method_sig_regex();

# linux:
#   libX.so.3.9.4
#   libX.so.3.9
#   libX.so.3
#   libX.so
# darwin:
#   libX.3.9.4.so
#   libX.3.9.so
#   libX.3.so
#   libX.so
sub is_so_path {
  my ($name) = @_;
  # linux and darwin so-regexs are combined
  my $result = $name =~ m=^(.*/)?(lib([.\w-]+))(\.$so_ext((\.\d+)+)?|((\.\d+)+)?\.$so_ext)$=; # so-regex
  #my $libname = $2 . ".$so_ext";
  return $result;
}
sub is_cc_path {
  my ($arg) = @_;
  if ($arg =~ m/\.$cc_ext$/) {
    return 1;
  } else {
    return 0;
  }
}
sub is_dk_src_path {
  my ($arg) = @_;
  if ($arg =~ m/\.dk$/ ||
      $arg =~ m/\.ctlg(\.\d+)*$/) {
    return 1;
  } else {
    return 0;
  }
}
sub is_ast_input_path { # dk, ctlg, or so
  my ($arg) = @_;
  if (&is_so_path($arg) || &is_dk_src_path($arg)) {
    return 1;
  } else {
    return 0;
  }
}
sub is_ast_path { # ast
  my ($arg) = @_;
  if ($arg =~ m/\.ast$/) {
    return 1;
  } else {
    return 0;
  }
}
sub is_o_path { # $o_ext
  my ($arg) = @_;
  if ($arg =~ m/\.$o_ext$/) {
    return 1;
  } else {
    return 0;
  }
}
sub is_ctlg_path { # ctlg
  my ($arg) = @_;
  if ($arg =~ m/\.ctlg(\.\d+)*$/) {
    return 1;
  } else {
    return 0;
  }
}
sub loop_merged_ast_from_inputs {
  my ($cmd_info, $should_echo) = @_; 
  if ($should_echo) {
    print STDERR '  &loop_merged_ast_from_inputs --output ' .
      $$cmd_info{'opts'}{'output'} . ' ' . join(' ', @{$$cmd_info{'inputs'}}) . $nl;
  }
  &init_ast_from_inputs_vars($cmd_info);
  my $ast_files = [];
  if ($$cmd_info{'asts'}) {
    $ast_files = $$cmd_info{'asts'};
  }
  my $ast;
  my $root_ast_path;
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_src_path($input)) {
      $ast = &ast_from_dk_path($input);
      my $ast_path;
      if (&is_dk_path($input)) {
        $ast_path = &ast_path_from_dk_path($input);
      } elsif (&is_ctlg_path($input)) {
        $ast_path = &ast_path_from_ctlg_path($input);
      } else {
        die;
      }
      &check_path($ast_path);
      $root_ast_path = $ast_path;
      &add_last($ast_files, $ast_path); # _from_dk_src_path
    } elsif (&is_ast_path($input)) {
      $ast = &scalar_from_file($input);
      $root_ast_path = $input;
      &add_last($ast_files, $input);
    } else {
      die __FILE__, ":", __LINE__, ": ERROR\n";
    }
  }
  if ($$cmd_info{'opts'}{'output'} && !exists $$cmd_info{'opts'}{'ctlg'}) {
    if (1 == @{$$cmd_info{'inputs'}}) {
      &scalar_to_file($$cmd_info{'opts'}{'output'}, $ast);
    } elsif (1 < @{$$cmd_info{'inputs'}}) {
      my $should_translate;
      &ast_merge($$cmd_info{'opts'}{'output'}, $ast_files, $should_translate = 0);
    }
  }
} # loop_merged_ast_from_inputs
sub add_visibility_file {
  my ($ast_path) = @_;
  #print STDERR "&add_visibility_file(path=\"$ast_path\")\n";
  my $ast = &scalar_from_file($ast_path);
  &add_visibility($ast);
  &scalar_to_file($ast_path, $ast);
}
my $debug_exported = 0;
sub add_visibility {
  my ($ast) = @_;
  my $debug = 0;
  my $names = [keys %{$$ast{'modules'}}];
  foreach my $name (@$names) {
    my $tbl = $$ast{'modules'}{$name}{'export'};
    my $strs = [sort keys %$tbl];
    foreach my $str (@$strs) {
      $str =~ s/\s*;\s*$//;
      $str =~ s/\s*\{\s*slots\s*;\s*\}\s*$/::slots-t/;
      my $seq = $$tbl{$str};
      if ($debug) { print STDERR "export module $name $str;\n"; }
      if (0) {
      } elsif ($str =~ /^((klass)\s+)?($rid)::(slots-t)$/) {
        my ($klass_type, $klass_name, $type_name) = ($2, $3, $4);
        # klass slots
        if ($debug) { print STDERR "$klass_type    slots:  $klass_name|$type_name\n"; }
        if ($$ast{'klasses'}{$klass_name} &&
            $$ast{'klasses'}{$klass_name}{'slots'} &&
            $$ast{'klasses'}{$klass_name}{'slots'}{'module'} eq $name) {
          $$ast{'klasses'}{$klass_name}{'slots'}{'is-exported'} = 1;
          if ($debug_exported) {
            $$ast{'klasses'}{$klass_name}{'slots'}{'is-exported'} = __FILE__ . '::' . __LINE__;
          }
        }
      } elsif ($str =~ /^((klass|trait)\s+)?($rid)$/) {
        my ($klass_type, $klass_name) = ($2, $3);
        # klass/trait
        if ($debug) { print STDERR "klass-type: <$klass_type>:        klass-name: <$klass_name>\n"; }
        if ($$ast{'klasses'}{$klass_name} &&
            $$ast{'klasses'}{$klass_name}{'module'} &&
            $$ast{'klasses'}{$klass_name}{'module'} eq $name) {
          $$ast{'klasses'}{$klass_name}{'is-exported'} = 1;
          if ($debug_exported) {
            $$ast{'klasses'}{$klass_name}{'is-exported'} = __FILE__ . '::' . __LINE__;
          }
        }
        if ($$ast{'traits'}{$klass_name}) {
          $$ast{'traits'}{$klass_name}{'is-exported'} = 1;
          if ($debug_exported) {
            $$ast{'traits'}{$klass_name}{'is-exported'} = __FILE__ . '::' . __LINE__;
          }
        }
      } elsif ($str =~ /^((klass|trait)\s+)?($rid)::($msig)$/) {
        my ($klass_type, $klass_name, $method_name) = ($2, $3, $4);
        # klass/trait method
        if ($debug) { print STDERR "$klass_type method $klass_name:$method_name\n"; }
        foreach my $constructs ('klasses', 'traits') {
          if ($$ast{$constructs}{$klass_name} &&
              $$ast{$constructs}{$klass_name}{'module'} eq $name) {
            foreach my $method_type ('slots-methods', 'methods') {
              if ($debug) { print STDERR &Dumper($$ast{$constructs}{$klass_name}); }
              while (my ($sig, $scope) = each (%{$$ast{$constructs}{$klass_name}{$method_type}})) {
                my $sig_min = &sig1($scope);
                if ($method_name =~ m/\(\)$/) {
                  $sig_min =~ s/\(.*?\)$/\(\)/;
                }
                if ($debug) { print STDERR "$sig == $method_name\n"; }
                if ($debug) { print STDERR "$sig_min == $method_name\n"; }
                if ($sig_min eq $method_name) {
                  if ($debug) { print STDERR "$sig == $method_name\n"; }
                  if ($debug) { print STDERR "$sig_min == $method_name\n"; }
                  $$scope{'is-exported'} = 1;
                  if ($debug_exported) {
                    $$scope{'is-exported'} = __FILE__ . '::' . __LINE__; 
                  }
                }
              }
            }
          }
        }
      } else {
        print STDERR "error: not klass/trait/slots/method: $str\n";
      }
    }
  }
}
sub src::add_extra_generics {
  my ($file) = @_;
  my $generics = $$extra{'src_extra_generics'};
  foreach my $generic (sort keys %$generics) {
    &add_generic($file, $generic);
  }
}
sub src::add_extra_keywords {
  my ($file) = @_;
  my $keywords = $$extra{'src_extra_keywords'};
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
sub target::add_extra_keywords {
  my ($file) = @_;
  my $keywords = $$extra{'target_extra_keywords'};
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
###
sub src::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = $$extra{'src_extra_klass_decls'};
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
sub target::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = $$extra{'target_extra_klass_decls'};
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
###
sub src::add_extra_symbols {
  my ($file) = @_;
  my $symbols = $$extra{'src_extra_symbols'};
  foreach my $symbol (sort keys %$symbols) {
    &add_symbol($file, $symbol);
  }
}
sub target::add_extra_symbols {
  my ($file) = @_;
  my $symbols = $$extra{'target_extra_symbols'};
  foreach my $symbol (sort keys %$symbols) {
    &add_symbol($file, $symbol);
  }
}
sub sig1 {
  my ($scope) = @_;
  my $result = '';
  $result .= &ct($$scope{'name'});
  $result .= '(';
  $result .= &ct($$scope{'param-types'}[0]);
  $result .= ')';
  return $result;
}
sub target_srcs_ast_path {
  my ($cmd_info) = @_;
  my $target_srcs_ast_path = &target_builddir() . '/srcs.ast';
  return $target_srcs_ast_path;
}
sub target_h_path {
  my ($cmd_info) = @_;
  my $target_h_path = &target_builddir() . '/target.' . $h_ext;
  return $target_h_path;
}
sub target_cc_path {
  my ($cmd_info) = @_;
  my $target_cc_path = &target_builddir() . '/target.' . $cc_ext;
  return $target_cc_path;
}
sub target_o_path {
  my ($cmd_info, $target_cc_path) = @_;
  my $target_o_path;
  my $project_io = &project_io_from_file($$cmd_info{'project.io'});
  if ($$project_io{'target-cc'} && $$project_io{'compile'}{$$project_io{'target-cc'}}) {
    $target_o_path = $$project_io{'compile'}{$$project_io{'target-cc'}};
  } else {
    $target_o_path = &o_path_from_cc_path($target_cc_path);
    #print STDERR "target_o_path=$target_o_path not in project.io" . $nl;
  }
  return $target_o_path;
}
sub default_cmd_info {
  my $cmd_info = { 'project.target' => &global_project_target() };
  return $cmd_info;
}
sub rel_target_h_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_cc_path($cmd_info) =~ s=^$builddir/(.+?)\.$cc_ext$=$1.$h_ext=r;
  return $result;
}
sub target_klass_func_decls_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_cc_path($cmd_info) =~ s=^$builddir/\+/(.+?)\.$cc_ext$=$1-klass-func-decls.inc=r;
  return $result;
}
sub target_klass_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_cc_path($cmd_info) =~ s=^$builddir/\+/(.+?)\.$cc_ext$=$1-klass-func-defns.inc=r;
  return $result;
}
sub target_generic_func_decls_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_cc_path($cmd_info) =~ s=^$builddir/\+/(.+?)\.$cc_ext$=$1-generic-func-decls.inc=r;
  return $result;
}
sub target_generic_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_cc_path($cmd_info) =~ s=^$builddir/\+/(.+?)\.$cc_ext$=$1-generic-func-defns.inc=r;
  return $result;
}
sub dk_parse {
  my ($dk_path) = @_; # string.dk
  my $ast_path = &ast_path_from_dk_path($dk_path);
  my $ast = &scalar_from_file($ast_path);
  $ast = &kw_args_translate($ast);
  return $ast;
}
sub loop_cc_from_dk {
  my ($cmd_info, $should_echo) = @_;
  if ($should_echo) {
    print STDERR '  &loop_cc_from_dk --output ' .
      $$cmd_info{'opts'}{'output'} . ' ' . join(' ', @{$$cmd_info{'inputs'}}) . $nl;
  }
  my $inputs = [];
  my $asts;
  if ($$cmd_info{'asts'}) {
    $asts = $$cmd_info{'asts'};
  } else {
    $asts = [];
  }
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_ast_path($input)) {
      &add_last($asts, $input);
    } else {
      &add_last($inputs, $input);
    }
  }
  $$cmd_info{'asts'} = $asts;
  $$cmd_info{'inputs'} = $inputs;

  my $target_inputs_ast = &target_inputs_ast($$cmd_info{'asts'}); # within loop_cc_from_dk
  my $num_inputs = @{$$cmd_info{'inputs'}};
  if (0 == $num_inputs) {
    die "$0: error: arguments are requried\n";
  }
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    my $ast_path;
    if (&is_so_path($input)) {
      my $ctlg_path = &ctlg_path_from_so_path($input);
      $ast_path = &ast_path_from_ctlg_path($ctlg_path);
      &check_path($ast_path);
    } elsif (&is_dk_src_path($input)) {
      $ast_path = &ast_path_from_dk_path($input);
      &check_path($ast_path);
    } else {
      #print "skipping $input, line=" . __LINE__ . $nl;
    }

    my ($input_dir, $input_name) = &split_path($input, $id);
    my $file_ast = &dk_parse($input);
    my $cc_path;
    if ($$cmd_info{'opts'}{'output'}) {
      $cc_path = $$cmd_info{'opts'}{'output'};
    } else {
      $cc_path = "$input_dir/$input_name.$cc_ext";
    }
    my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    my $inc_path = &inc_path_from_dk_path($input);
    my $h_path = $cc_path =~ s/\.$cc_ext$/\.$h_ext/r;
    $input = &canon_path($input);
    &empty_klass_defns();
    &dk_generate_cc($input, $inc_path, $target_inputs_ast);
    &src::add_extra_symbols($file_ast);
    &src::add_extra_klass_decls($file_ast);
    &src::add_extra_keywords($file_ast);
    &src::add_extra_generics($file_ast);
    my $rel_target_h_path = &rel_target_h_path($cmd_info);

    &generate_src_decl($cc_path, $file_ast, $target_inputs_ast, $rel_target_h_path);
    &generate_src_defn($cc_path, $file_ast, $target_inputs_ast, $rel_target_h_path); # rel_target_h_path not used
  }
  return $num_inputs;
} # loop_cc_from_dk

sub gcc_library_from_library_name {
  my ($library_name) = @_;
  # linux and darwin so-regexs are separate
  if ($library_name =~ m=^lib([.\w-]+)\.$so_ext((\.\d+)+)?$= ||
      $library_name =~ m=^lib([.\w-]+)((\.\d+)+)?\.$so_ext$=) { # so-regex
    my $library_name_base = $1;
    return "-l$library_name_base"; # hardhard: hardcoded use of -l (both gcc/clang use it)
  } else {
    return "-l$library_name";
  }
}
sub cmd_opts_from_library_name {
  my ($lib) = @_;
  my $path = $lib;
  if (&is_so_path($lib) && $lib !~ m|/| && -e $lib) {
    $path = './' . $lib;
  }
  return &cmd_opts_from_library_path($path);
}
sub cmd_opts_from_library_path {
  my ($lib) = @_;

  my $result = '';
  # linux and darwin so-regexs are separate
  if ($lib =~ m=^(.*/)?(lib([.\w-]+))\.$so_ext((\.\d+)+)?$= ||
      $lib =~ m=^(.*/)?(lib([.\w-]+))((\.\d+)+)?\.$so_ext$=) { # so-regex
    my $library_directory = $1;
    my $library_name = $2 . ".$so_ext";
    if ($library_directory && 0 != length($library_directory)) {
      $library_directory = &canon_path($library_directory);
      $result .= "--library-directory=$library_directory --for-linker -rpath --for-linker $library_directory ";
    }
    $result .= &gcc_library_from_library_name($library_name);
  } else {
    $result = $lib;
  }
  return $result;
}
sub inputs_tbl {
  my ($inputs) = @_;
  my $result = {};
  foreach my $input (@$inputs) {
    my $cmd_opts = &cmd_opts_from_library_name($input);
    if ($cmd_opts ne $input) {
      $$result{$input} = $cmd_opts;
    }
  }
  return $result;
}
sub for_linker {
  my ($tkns) = @_;
  my $for_linker = &var($gbl_compiler, 'CXX_FOR_LINKER_FLAGS', [ '--for-linker' ]);
  my $result = '';
  foreach my $tkn (@$tkns) {
    $result .= ' ' . $for_linker . ' ' . $tkn;
  }
  return $result;
}
sub update_kw_arg_generics {
  my ($asts) = @_;
  my $kw_arg_generics = {};
  foreach my $path (@$asts) {
    my $ast = &scalar_from_file($path);
    my $tbl = $$ast{'kw-arg-generics'};
    if ($tbl) {
      while (my ($name, $params_tbl) = each(%$tbl)) {
        while (my ($params_str, $params) = each(%$params_tbl)) {
          $$kw_arg_generics{$name}{$params_str} = $params;
        }
      }
    }
  }
  my $path = $$asts[-1]; # only update the project file ast
  my $ast = &scalar_from_file($path);
  $$ast{'kw-arg-generics'} = $kw_arg_generics;
  &scalar_to_file($path, $ast);
}
sub update_target_srcs_ast_from_all_inputs {
  my ($cmd_info, $target_srcs_ast_path) = @_;
  my $orig = { 'inputs' => $$cmd_info{'inputs'},
               'output' => $$cmd_info{'output'},
               'opts' =>   &deep_copy($$cmd_info{'opts'}),
             };
  $$cmd_info{'inputs'} = $$cmd_info{'project.inputs'},
  $$cmd_info{'output'} = $$cmd_info{'project.target'},
  $$cmd_info{'opts'}{'echo-inputs'} = 0;
  $$cmd_info{'opts'}{'silent'} = 1;
  delete $$cmd_info{'opts'}{'compile'};
  &check_path($target_srcs_ast_path);
  $cmd_info = &loop_ast_from_so($cmd_info);
  $cmd_info = &loop_ast_from_inputs($cmd_info);
  die if $$cmd_info{'asts'}[-1] ne $target_srcs_ast_path; # assert
  &add_visibility_file($target_srcs_ast_path);

  &update_kw_arg_generics($$cmd_info{'asts'});
  $$cmd_info{'inputs'} = $$orig{'inputs'};
  $$cmd_info{'output'} = $$orig{'output'};
  $$cmd_info{'opts'} =   $$orig{'opts'};

  if ($ENV{'DAKOTA_CREATE_AST_ONLY'}) {
    exit 0;
  }
  return $cmd_info;
}
sub add_target_o_path_to_inputs {
  my ($cmd_info) = @_;
  $$cmd_info{'inputs'} = &clean_paths($$cmd_info{'inputs'});
  my $target_cc_path = &target_cc_path($cmd_info);
  my $target_o_path =  &target_o_path($cmd_info, $target_cc_path);
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    return if $input eq $target_o_path;
  }
  &add_first($$cmd_info{'inputs'}, $target_o_path);
  $$cmd_info{'inputs'} = &clean_paths($$cmd_info{'inputs'});
}
my $root_cmd;
sub start_cmd {
  my ($cmd_info, $project) = @_;
  $root_cmd = $cmd_info;
  my $is_exe = &is_exe($cmd_info, $project);
  if ($is_exe) {
    $dk_exe_type = '#exe';
  } else {
    $dk_exe_type = '#lib';
  }
  $builddir = &builddir();
  if ($$cmd_info{'opts'}{'target'} && $$cmd_info{'opts'}{'path-only'}) {
    my $target_cc_path = &target_cc_path($cmd_info);
    print $target_cc_path . $nl;
    return $exit_status;
  }
  if (!$$cmd_info{'opts'}{'compiler'}) {
    my $cxx = &var($gbl_compiler, 'CXX', 'g++');
    $$cmd_info{'opts'}{'compiler'} = $cxx;
  }
  if (!$$cmd_info{'opts'}{'compiler-flags'}) {
    my $cxxflags =       &var($gbl_compiler, 'CXXFLAGS', [ '-std=c++1z', '--visibility=hidden' ]);
    my $extra_cxxflags = &var($gbl_compiler, 'EXTRA_CXXFLAGS', '');
    $$cmd_info{'opts'}{'compiler-flags'} = $cxxflags . ' ' . $extra_cxxflags;
  }
  my $ld_soname_flags =    &var_array($gbl_compiler, 'LD_SONAME_FLAGS', '-soname');
  my $no_undefined_flags = &var_array($gbl_compiler, 'LD_NO_UNDEFINED_FLAGS', '--no-undefined');
  &add_last($ld_soname_flags, $$cmd_info{'opts'}{'soname'});
  if ($$cmd_info{'opts'}{'compile'}) {
    $dk_exe_type = undef;
  } elsif ($$cmd_info{'opts'}{'shared'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
      $cxx_shared_flags .= &for_linker($ld_soname_flags);
    }
    $cxx_shared_flags .= &for_linker($no_undefined_flags);
  } elsif ($$cmd_info{'opts'}{'dynamic'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
      $cxx_dynamic_flags .= &for_linker($ld_soname_flags);
    }
    $cxx_dynamic_flags .= &for_linker($no_undefined_flags);
  } elsif (!$$cmd_info{'opts'}{'compile'}
	   && !$$cmd_info{'opts'}{'shared'}
	   && !$$cmd_info{'opts'}{'dynamic'}) {
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  $$cmd_info{'output'} = $$cmd_info{'opts'}{'output'}; ###
  if ($should_replace_library_path_with_lib_opts) {
    $$cmd_info{'inputs-tbl'} = &inputs_tbl($$cmd_info{'inputs'});
  }
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  my $lock_file = $target_srcs_ast_path . '.flock';
  &make_dir_part($target_srcs_ast_path);

  my $should_lock = 0;
  if ($should_lock) {
    open(LOCK_FILE, ">", $lock_file) or die __FILE__, ":", __LINE__, ": ERROR: $lock_file: $!\n";
    flock LOCK_FILE, LOCK_EX or die;
  }
  $cmd_info = &update_target_srcs_ast_from_all_inputs($cmd_info, $target_srcs_ast_path); # BUGUBUG: called even when not out of date
  if ($$cmd_info{'opts'}{'parse'}) {
    print $target_srcs_ast_path . $nl;
    if ($should_lock) {
      flock LOCK_FILE, LOCK_UN or die;
      close LOCK_FILE or die __FILE__, ":", __LINE__, ": ERROR: $lock_file: $!\n";
      unlink $lock_file;
    }
    return $exit_status;
  }
  &set_target_srcs_ast($target_srcs_ast_path);

  if (!$ENV{'DK_SRC_UNIQUE_HEADER'} || $ENV{'DK_INLINE_GENERIC_FUNCS'} || $ENV{'DK_INLINE_KLASS_FUNCS'}) {
    if (!$$cmd_info{'opts'}{'compile'}) {
        &gen_target_h($cmd_info, $is_exe);
    }
  }
  if ($should_lock) {
    flock LOCK_FILE, LOCK_UN or die;
    close LOCK_FILE or die __FILE__, ":", __LINE__, ": ERROR: $lock_file: $!\n";
    unlink $lock_file;
  }

  if ($ENV{'DK_GENERATE_TARGET_FIRST'}) {
    # generate the single (but slow) runtime .o, then the user .o files
    # this might be useful for distributed building (initiating the building of the slowest first
    # or for testing runtime code generation
    # also, this might be useful if the runtime .h file is being used rather than generating a
    # translation unit specific .h file (like in the case of inline funcs)
    if (!$$cmd_info{'opts'}{'compile'}) {
      if (!$$cmd_info{'opts'}{'init'}) {
          &gen_target_o($cmd_info, $is_exe);
      }
    }
    if (!$$cmd_info{'opts'}{'init'} && !$$cmd_info{'opts'}{'target'}) {
      $cmd_info = &loop_o_from_dk($cmd_info);
    }
  } else {
     # generate user .o files first, then the single (but slow) runtime .o
    if (!$$cmd_info{'opts'}{'init'} && !$$cmd_info{'opts'}{'target'}) {
      $cmd_info = &loop_o_from_dk($cmd_info);
    }
    if (!$$cmd_info{'opts'}{'compile'}) {
      if (!$$cmd_info{'opts'}{'init'}) {
          &gen_target_o($cmd_info, $is_exe);
      }
    }
  }
  if (!$$cmd_info{'opts'}{'precompile'} && !$$cmd_info{'opts'}{'init'} && !$$cmd_info{'opts'}{'target'}) {
    if ($$cmd_info{'opts'}{'compile'}) {
      if ($want_separate_precompile_pass) {
        &o_from_cc($cmd_info, &compile_opts_path(), $cxx_compile_flags);
      }
    } elsif ($$cmd_info{'opts'}{'shared'}) {
      &add_target_o_path_to_inputs($cmd_info);
      &linked_output_from_o($cmd_info, &link_so_opts_path(), $cxx_shared_flags);
    } elsif ($$cmd_info{'opts'}{'dynamic'}) {
      &add_target_o_path_to_inputs($cmd_info);
      &linked_output_from_o($cmd_info, &link_dso_opts_path(), $cxx_dynamic_flags);
    } elsif (!$$cmd_info{'opts'}{'compile'} &&
             !$$cmd_info{'opts'}{'shared'}  &&
             !$$cmd_info{'opts'}{'dynamic'}) {
      &add_target_o_path_to_inputs($cmd_info);
      if ($is_exe) {
        my $mode_flags;
        &linked_output_from_o($cmd_info, &link_exe_opts_path(), $mode_flags = undef);
      } else {
        # default to shared, not dynamic
        &linked_output_from_o($cmd_info, &link_so_opts_path(), $cxx_shared_flags);
      }
    } else {
      die __FILE__, ":", __LINE__, ": error:\n";
    }
  }
  return $exit_status;
}
sub ast_from_so {
  my ($cmd_info, $arg) = @_;
  if (!$arg) {
    $arg = $$cmd_info{'input'};
  }
  my $ctlg_path = &ctlg_path_from_so_path($arg);
  my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$ctlg_cmd{'project.io'} = $$cmd_info{'project.io'};
  $$ctlg_cmd{'output'} = $ctlg_path;
  if (0) {
    my ($ctlg_dir, $ctlg_file) = &split_path($ctlg_path);
    $$ctlg_cmd{'output-directory'} = $ctlg_dir; # writes individual klass ctlgs (one per file)
  }
  $$ctlg_cmd{'inputs'} = [ $arg ];
  &ctlg_from_so($ctlg_cmd);
  my $ast_path = &ast_path_from_ctlg_path($ctlg_path);
  &check_path($ast_path);
  &ordered_set_add($$cmd_info{'asts'}, $ast_path, __FILE__, __LINE__);
  my $ast_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$ast_cmd{'output'} = $ast_path;
  $$ast_cmd{'inputs'} = [ $ctlg_path ];
  $$ast_cmd{'project.io'} =  $$cmd_info{'project.io'};
  &ast_from_inputs($ast_cmd);
  if (!$should_write_ctlg_files) {
    #unlink $ctlg_path;
  }
}
sub loop_ast_from_so {
  my ($cmd_info) = @_;
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_so_path($input)) {
      &ast_from_so($cmd_info, $input);
      my $ctlg_path = &ctlg_path_from_so_path($input);
      my $ast_path = &ast_path_from_ctlg_path($ctlg_path);
      $input = &canon_path($input);
    }
  }
  return $cmd_info;
} # loop_ast_from_so
sub check_path {
  my ($path) = @_;
  die if $path =~ m=^build/build/=;
  die if $path =~ m=^build/+{rt|user}/build/=;
}
sub ast_from_inputs {
  my ($cmd_info) = @_;
  my $ast_cmd = {
    'cmd' =>         '&loop_merged_ast_from_inputs',
    'opts' =>        $$cmd_info{'opts'},
    'output' =>      $$cmd_info{'output'},
    'inputs' =>      $$cmd_info{'inputs'},
    'project.io' =>  $$cmd_info{'project.io'},
    'project.target' =>  $$cmd_info{'project.target'},
  };
  my $should_echo;
  my $result = &outfile_from_infiles($ast_cmd, $should_echo = 0);
  if ($result) {
    if (0 != @{$$ast_cmd{'asts'} || []}) {
      my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    }
    foreach my $input (@{$$ast_cmd{'inputs'}}) {
      if (&is_so_path($input)) {
        my $ctlg_path = &ctlg_path_from_so_path($input);
        my $ast_path = &ast_path_from_ctlg_path($ctlg_path);
        &check_path($ast_path);
      } elsif (&is_dk_path($input)) {
        my $ast_path = &ast_path_from_dk_path($input);
        &check_path($ast_path);
      } elsif (&is_ctlg_path($input)) {
        my $ast_path = &ast_path_from_ctlg_path($input);
        &check_path($ast_path);
      } else {
        #print "skipping $input, line=" . __LINE__ . $nl;
      }
    }
  }
  return $result;
}
sub loop_ast_from_inputs {
  my ($cmd_info) = @_;
  my $ast_files = [];
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_src_path($input)) {
      my $ast_path = &ast_path_from_dk_path($input);
      &check_path($ast_path);
      my $ast_cmd = {
        'opts' =>        $$cmd_info{'opts'},
        'project.io' =>  $$cmd_info{'project.io'},
        'output' => $ast_path,
        'inputs' => [ $input ],
      };
      &ast_from_inputs($ast_cmd);
      &ordered_set_add($ast_files, $ast_path, __FILE__, __LINE__);
    } elsif (&is_ast_path($input)) {
      &ordered_set_add($ast_files, $input, __FILE__, __LINE__);
    }
  }
  die if ! $$cmd_info{'output'};
  if ($$cmd_info{'output'} && !$$cmd_info{'opts'}{'compile'}) {
    if (0 != @$ast_files) {
      my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
      &check_path($target_srcs_ast_path);
      &ordered_set_add($$cmd_info{'asts'}, $target_srcs_ast_path, __FILE__, __LINE__);
      my $ast_cmd = {
        'opts' =>        $$cmd_info{'opts'},
        'project.io' =>  $$cmd_info{'project.io'},
        'output' => $target_srcs_ast_path,
        'inputs' => $ast_files,
      };
      &ast_from_inputs($ast_cmd); # multiple inputs
    }
  }
  return $cmd_info;
} # loop_ast_from_inputs
sub gen_target_h {
  my ($cmd_info, $is_exe) = @_;
  my $is_defn;
  return &gen_target($cmd_info, $is_exe, $is_defn = 0);
}
sub gen_target_o {
  my ($cmd_info, $is_exe) = @_;
  my $is_defn;
  return &gen_target($cmd_info, $is_exe, $is_defn = 1);
}
sub gen_target {
  my ($cmd_info, $is_exe, $is_defn) = @_;
  die if ! $$cmd_info{'output'};
  if ($$cmd_info{'output'}) {
    my $target_cc_path = &target_cc_path($cmd_info);
    my $target_h_path = &builddir() . '/' . &rel_target_h_path($cmd_info);
    if ($$cmd_info{'opts'}{'echo-inputs'}) {
      my $target_dk_path = &dk_path_from_cc_path($target_cc_path);
      print $target_dk_path . $nl;
    }
  }
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  &check_path($target_srcs_ast_path);
  $$cmd_info{'ast'} = $target_srcs_ast_path;
  my $flags = $$cmd_info{'opts'}{'compiler-flags'};
  my $other = {};
  if ($dk_exe_type) {
    $$other{'type'} = $dk_exe_type;
  }
  die if ! $$cmd_info{'output'};
  if ($$cmd_info{'opts'}{'soname'}) {
    $$other{'name'} = $$cmd_info{'opts'}{'soname'};
  } elsif ($$cmd_info{'output'}) {
    $$other{'name'} = $$cmd_info{'output'};
  }
  $$cmd_info{'opts'}{'compiler-flags'} = $flags;
  if (!$is_defn) {
    &target_h_from_ast($cmd_info, $other, $is_exe);
  } else {
    &target_o_from_ast($cmd_info, $other, $is_exe);
  }
} # gen_target_o
sub o_from_dk {
  my ($cmd_info, $input) = @_;
  my $ast_path = &ast_path_from_dk_path($input);
  my $num_out_of_date_infiles = 0;
  my $outfile;
  if (!&is_dk_src_path($input)) {
    if ($$cmd_info{'opts'}{'echo-inputs'}) {
      #print $input . $nl; # dk_path
    }
    $outfile = $input;
  } else {
    my $inc_path = &inc_path_from_dk_path($input);
    my $o_path;
    if ($$cmd_info{'output'} && &is_o_path($$cmd_info{'output'})) {
      $o_path = $$cmd_info{'output'};
    } else {
      $o_path =  &o_path_from_dk_path($input);
    }
    my $src_path = &cc_path_from_dk_path($input);
    my $h_path = &h_path_from_src_path($src_path);
    if (!$want_separate_ast_pass) {
      &check_path($ast_path);
      my $ast_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$ast_cmd{'inputs'} = [ $input ];
      $$ast_cmd{'output'} = $ast_path;
      $$ast_cmd{'project.io'} =  $$cmd_info{'project.io'};
      $num_out_of_date_infiles = &ast_from_inputs($ast_cmd);
      &ordered_set_add($$cmd_info{'asts'}, $ast_path, __FILE__, __LINE__);
    }
    my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$cc_cmd{'inputs'} = [ $input ];
    $$cc_cmd{'output'} = $src_path;
    $$cc_cmd{'asts'} = $$cmd_info{'asts'};
    $$cc_cmd{'project.io'} =  $$cmd_info{'project.io'};
    $$cc_cmd{'project.target'} = $$cmd_info{'project.target'};
    $num_out_of_date_infiles = &cc_from_dk($cc_cmd);
    if ($num_out_of_date_infiles) {
      my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    }
    if ($$cmd_info{'opts'}{'precompile'}) {
      $outfile = $$cc_cmd{'output'};
      if ($num_out_of_date_infiles) {
        &echo_output_path($outfile); # required by bin/dk
      }
    } else {
      my $o_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$o_cmd{'inputs'} = [ $src_path ];
      $$o_cmd{'output'} = $o_path;
      $$o_cmd{'project.io'} =  $$cmd_info{'project.io'};
      delete $$o_cmd{'opts'}{'output'};
      $num_out_of_date_infiles = &o_from_cc($o_cmd, &compile_opts_path(), $cxx_compile_flags);

      &project_io_add($$cmd_info{'project.io'}, 'compile', $input, $o_path); # should also be in dk
      $outfile = $$o_cmd{'output'};
    }
  }
  return $outfile;
} # o_from_dk
sub loop_o_from_dk {
  my ($cmd_info) = @_;
  my $outfiles = [];
  my $output;
  my $has_multiple_inputs = 0;
  $has_multiple_inputs = 1 if 1 > @{$$cmd_info{'inputs'}};

  if ($has_multiple_inputs) {
    $output = $$cmd_info{'output'};
    $$cmd_info{'output'} = undef;
  }
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_path($input)) {
      &add_last($outfiles, &o_from_dk($cmd_info, $input));
    } elsif (&is_cc_path($input)) {
      &add_last($outfiles, &o_from_cc($cmd_info, &compile_opts_path(), $cxx_compile_flags));
    } else {
      &add_last($outfiles, $input);
    }
  }
  if ($has_multiple_inputs) {
    $$cmd_info{'output'} = $output;
  }
  $$cmd_info{'inputs'} = $outfiles;
  delete $$cmd_info{'opts'}{'output'}; # hackhack
  return $cmd_info;
} # loop_o_from_dk
sub cc_from_dk {
  my ($cmd_info) = @_;
  my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$cc_cmd{'project.io'} =  $$cmd_info{'project.io'};
  $$cc_cmd{'project.target'} = $$cmd_info{'project.target'};
  $$cc_cmd{'cmd'} = '&loop_cc_from_dk';
  $$cc_cmd{'asts'} = $$cmd_info{'asts'};
  $$cc_cmd{'output'} = $$cmd_info{'output'};
  $$cc_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  return &outfile_from_infiles($cc_cmd, $should_echo = 0);
}
sub common_opts_path {
  return $builddir . '/cxx-common.opts';
}
sub compile_opts_path {
  return $builddir . '/cxx-compile.opts';
}
sub link_so_opts_path {
  return $builddir . '/cxx-link-so.opts';
}
sub link_exe_opts_path {
  return $builddir . '/cxx-link-exe.opts';
}
sub o_from_cc {
  my ($cmd_info, $opts_path, $mode_flags) = @_;
  my $opts = $$cmd_info{'opts'}{'compiler-flags'};
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  &filestr_to_file($opts, &common_opts_path());
  $opts =
    $mode_flags . $nl .
      '@' . &common_opts_path() . $nl;
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  &filestr_to_file($opts, $opts_path);
  my $o_cmd = { 'opts' => $$cmd_info{'opts'}, 'inputs' => [] };
  $$o_cmd{'project.io'} =  $$cmd_info{'project.io'};
  $$o_cmd{'project.target'} = $$cmd_info{'project.target'};
  $$o_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
  $$o_cmd{'cmd-flags'} = '@' . $opts_path;
  $$o_cmd{'output'} = $$cmd_info{'output'};

  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_cc_path($input)) {
      &add_last($$o_cmd{'inputs'}, $input);
    }
  }
  my $should_echo = 0;
  if ($ENV{'DK_ECHO_COMPILE_CMD'}) {
    $should_echo = 1;
  }
  if (0) {
    $$o_cmd{'cmd-flags'} .= " -MMD";
    return &outfile_from_infiles($o_cmd, $should_echo);
    $$o_cmd{'cmd-flags'} =~ s/ -MMD//g;
  }
  my $count = &outfile_from_infiles($o_cmd, $should_echo);
  &project_io_add($$cmd_info{'project.io'}, 'compile', $$o_cmd{'inputs'}, $$o_cmd{'output'});
  return $count;
}
sub target_h_from_ast {
  my ($cmd_info, $other, $is_exe) = @_;
  my $is_defn;
  return &target_from_ast($cmd_info, $other, $is_exe, $is_defn = 0);
}
sub target_o_from_ast {
  my ($cmd_info, $other, $is_exe) = @_;
  my $is_defn;
  return &target_from_ast($cmd_info, $other, $is_exe, $is_defn = 1);
}
sub target_from_ast {
  my ($cmd_info, $other, $is_exe, $is_defn) = @_;
  die if ! defined $$cmd_info{'asts'} || 0 == @{$$cmd_info{'asts'}};
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  my $target_cc_path =  &target_cc_path($cmd_info);
  my $target_h_path = &builddir() . '/' . &rel_target_h_path($cmd_info);
  &check_path($target_srcs_ast_path);
  my $target_o_path = &target_o_path($cmd_info, $target_cc_path);

  if ($is_defn) {
    if ($$cmd_info{'opts'}{'precompile'}) {
      return if !&is_out_of_date($target_srcs_ast_path, $target_cc_path);
    } else {
      return if !&is_out_of_date($target_srcs_ast_path, $target_o_path);
    }
  } else {
    return if !&is_out_of_date($target_srcs_ast_path, $target_h_path);
  }
  &make_dir_part($target_cc_path, $global_should_echo);
  my ($path, $file_basename, $target_srcs_ast) = ($target_cc_path, $target_cc_path, undef);
  $path =~ s|/[^/]*$||;
  $file_basename =~ s|^[^/]*/||;       # strip off leading $builddir/
  # $target_inputs_ast not used, called for side-effect
  my $target_inputs_ast = &target_inputs_ast($$cmd_info{'asts'}, $$cmd_info{'precompile'}); # within target_o_from_ast
  $target_srcs_ast = &scalar_from_file($target_srcs_ast_path);
  die if $$target_srcs_ast{'other'};
  $$target_srcs_ast{'other'} = $other;
  $target_srcs_ast = &kw_args_translate($target_srcs_ast);
  $$target_srcs_ast{'should-generate-make'} = 1;

  &target::add_extra_symbols($target_srcs_ast);
  &target::add_extra_klass_decls($target_srcs_ast);
  &target::add_extra_keywords($target_srcs_ast);

  &src::add_extra_symbols($target_srcs_ast);
  &src::add_extra_klass_decls($target_srcs_ast);
  &src::add_extra_keywords($target_srcs_ast);
  &src::add_extra_generics($target_srcs_ast);

  if ($is_defn) {
    &generate_target_defn($target_cc_path, $target_srcs_ast, $target_inputs_ast, $is_exe);
    &project_io_assign($$cmd_info{'project.io'}, 'target-cc', $target_cc_path);
  } else {
    &generate_target_decl($target_h_path, $target_srcs_ast, $target_inputs_ast, $is_exe);
  }

  if ($is_defn && !$$cmd_info{'opts'}{'precompile'}) {
  my $o_info = {'opts' => {}, 'inputs' => [ $target_cc_path ], 'output' => $target_o_path };
  $$o_info{'project.io'} =  $$cmd_info{'project.io'};
  if ($$cmd_info{'opts'}{'silent'}) {
    $$o_info{'opts'}{'silent'} = $$cmd_info{'opts'}{'silent'};
  }
  if ($$cmd_info{'opts'}{'precompile'}) {
    $$o_info{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
  }
  if ($$cmd_info{'opts'}{'compiler'}) {
    $$o_info{'opts'}{'compiler'} = $$cmd_info{'opts'}{'compiler'};
  }
  if ($$cmd_info{'opts'}{'compiler-flags'}) {
    $$o_info{'opts'}{'compiler-flags'} = $$cmd_info{'opts'}{'compiler-flags'};
  }
    &o_from_cc($o_info, &compile_opts_path(), $cxx_compile_flags);
    &add_first($$cmd_info{'inputs'}, $target_o_path);
    &project_io_add($$cmd_info{'project.io'}, 'compile', $target_cc_path, $target_o_path); # should also be in dk
  }
}
sub gcc_libraries_str {
  my ($library_names) = @_;
  my $gcc_libraries = [];
  foreach my $library_name (@$library_names) {
    &add_last($gcc_libraries, &gcc_library_from_library_name($library_name));
  }
  my $result = join(' ', @$gcc_libraries);
  return $result;
}
# adding first before any arguments (i.e. files (*.dk, *.$cc_ext, *.$so_ext, etc))
# but after all cmd-flags
sub library_names_add_first {
  my ($cmd_info) = @_;
  if ($$cmd_info{'opts'}{'library'} && 0 != @{$$cmd_info{'opts'}{'library'}}) {
    my $gcc_libraries_str = &gcc_libraries_str($$cmd_info{'opts'}{'library'});
    if (!defined $$cmd_info{'cmd-flags'}) {
      $$cmd_info{'cmd-flags'} = $gcc_libraries_str;
    } else {
      $$cmd_info{'cmd-flags'} .= ' ' . $gcc_libraries_str;
    }
  }
}
sub linked_output_from_o {
  my ($cmd_info, $opts_path, $mode_flags) = @_;
  my $cmd = { 'opts' => $$cmd_info{'opts'} };
  $$cmd{'project.io'} =  $$cmd_info{'project.io'};
  my $ldflags =       &var($gbl_compiler, 'LDFLAGS', '');
  my $extra_ldflags = &var($gbl_compiler, 'EXTRA_LDFLAGS', '');
  my $opts = '';
  $opts .= $mode_flags . $nl if $mode_flags;
  $opts .=
    $ldflags . $nl .
    $extra_ldflags . $nl .
    '@' . &common_opts_path() . $nl;
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  $opts .= $nl;
  &filestr_to_file($opts, $opts_path);
  $$cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
  $$cmd{'cmd-flags'} = '@' . $opts_path;
  $$cmd{'output'} = $$cmd_info{'output'};
  $$cmd{'project.target'} = $$cmd_info{'project.target'};
  $$cmd{'inputs'} =     $$cmd_info{'inputs'};
  $$cmd{'inputs-tbl'} = $$cmd_info{'inputs-tbl'};
  &library_names_add_first($cmd);
  my $should_echo = 0;
  if ($ENV{'DK_ECHO_LINK_CMD'} || $ENV{'DK_ECHO_LINK_EXE_CMD'}) {
    $should_echo = 1;
  }
  my $result = &outfile_from_infiles($cmd, $should_echo);
  return $result;
}
sub exec_cmd {
  my ($cmd_info, $should_echo) = @_;
  my $cmd_str;
  $cmd_str = &str_from_cmd_info($cmd_info);
  if (&is_debug() || $global_should_echo || $should_echo) {
    print STDERR $cmd_str . $nl;
  }
  if ($ENV{'DKT_INITIAL_WORKDIR'}) {
    open (STDERR, "|$gbl_prefix/bin/dakota-fixup-stderr $ENV{'DKT_INITIAL_WORKDIR'}") or die "$!";
  }
  else {
    open (STDERR, "|$gbl_prefix/bin/dakota-fixup-stderr") or die "$!";
  }
  my $exit_val = system($cmd_str);
  if (0 != $exit_val >> 8) {
    my $tmp_exit_status = $exit_val >> 8;
    if ($exit_status < $tmp_exit_status) { # similiar to behavior of gnu make
      $exit_status = $tmp_exit_status;
    }
    if (!$$root_cmd{'opts'}{'keep-going'}) {
      if (!(&is_debug() || $global_should_echo || $should_echo)) {
        print STDERR "  $cmd_str\n";
      }
      die "exit value from system() was $exit_val\n" if $exit_status == 0;
      exit $exit_status;
    }
  }
}
sub outfile_from_infiles {
  my ($cmd_info, $should_echo) = @_;
  my $outfile = $$cmd_info{'output'};
  &make_dir_part($outfile, $should_echo);
  if ($outfile =~ m|^$builddir/$builddir/|) { die "found double builddir/builddir: $outfile"; } # likely a double $builddir prepend
  my $file_db = {};
  my $infiles = &out_of_date($$cmd_info{'inputs'}, $outfile, $file_db);
  my $num_out_of_date_infiles = scalar @$infiles;
  if (0 != $num_out_of_date_infiles) {
    #print STDERR "outfile=$outfile, infiles=[ " . join(' ', @$infiles) . ' ]' . $nl;
    &make_dir_part($$cmd_info{'output'}, $should_echo);
    if ($show_outfile_info) {
      print "MK $$cmd_info{'output'}\n";
    }
    my $output = $$cmd_info{'output'};

    if (!&is_ast_path($output) &&
        !&is_ctlg_path($output)) {
      #$should_echo = 0;
      if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
        $output = $ENV{'DKT_DIR'} . '/' . $output
      }
    }
    if ('&loop_merged_ast_from_inputs' eq $$cmd_info{'cmd'}) {
      $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
      delete $$cmd_info{'output'};
      delete $$cmd_info{'cmd'};
      delete $$cmd_info{'cmd-flags'};
      &loop_merged_ast_from_inputs($cmd_info, $global_should_echo || $should_echo);
    } elsif ('&loop_cc_from_dk' eq $$cmd_info{'cmd'}) {
      $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
      delete $$cmd_info{'output'};
      delete $$cmd_info{'cmd'};
      delete $$cmd_info{'cmd-flags'};
      &loop_cc_from_dk($cmd_info, $global_should_echo || $should_echo);
    } else {
      &exec_cmd($cmd_info, $should_echo);
      if (!$$cmd_info{'opts'}{'silent'}) {
        &echo_output_path($output, &digsig(&filestr_from_file($output))) if &is_o_path($output);
      }
    }

    if (1) {
      foreach my $input (@$infiles) {
        $input =~ s=^--library-directory\s+(.+)\s+-l(.+)$=$1/lib$2.$so_ext=;
        $input = &canon_path($input);
      }
    }
  }
  return $num_out_of_date_infiles;
} # outfile_from_infiles
sub ctlg_from_so {
  my ($cmd_info) = @_;
  if ($$cmd_info{'opts'}{'echo-inputs'}) {
    #map { print '// ' . $_ . $nl; } @{$$cmd_info{'inputs'}};
  }
  my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$ctlg_cmd{'project.io'} =  $$cmd_info{'project.io'};

  if ($ENV{'DAKOTA_CATALOG'}) {
    $$ctlg_cmd{'cmd'} = $ENV{'DAKOTA_CATALOG'};
  } else {
    my $dakota_catalog_path = "$gbl_prefix/bin/dakota-catalog";
    if (-e $dakota_catalog_path) {
      $$ctlg_cmd{'cmd'} = $dakota_catalog_path;
    } else {
      $$ctlg_cmd{'cmd'} = 'dakota-catalog';
    }
  }
  if ($$cmd_info{'opts'}{'silent'} && !$$cmd_info{'opts'}{'echo-inputs'}) {
    $$ctlg_cmd{'cmd'} .= ' --silent';
  }
  $$ctlg_cmd{'output'} = $$cmd_info{'output'};
  $$ctlg_cmd{'project.target'} = $$cmd_info{'project.target'};
  $$ctlg_cmd{'output-directory'} = $$cmd_info{'output-directory'};

  if ($$cmd_info{'opts'}{'precompile'}) {
    $$ctlg_cmd{'inputs'} = &precompiled_inputs($cmd_info);
  } else {
    $$ctlg_cmd{'inputs'} = $$cmd_info{'inputs'};
  }
  #print &Dumper($ctlg_cmd);
  my $should_echo;
  return &outfile_from_infiles($ctlg_cmd, $should_echo = 0);
}
sub precompiled_inputs {
  my ($cmd_info) = @_;
  my $inputs = $$cmd_info{'inputs'};
  my $precompiled_inputs = [];
  foreach my $input (@$inputs) {
    if (-e $input) {
      &add_last($precompiled_inputs, $input);
    } else {
      my $ast_path;
      if (&is_so_path($input)) {
        my $ctlg_path = &ctlg_path_from_so_path($input);
        $ast_path = &ast_path_from_ctlg_path($ctlg_path);
        $input = &canon_path($input);
      } elsif (&is_dk_src_path($input)) {
        $ast_path = &ast_path_from_dk_path($input);
        &check_path($ast_path);
      } else {
        #print "skipping $input, line=" . __LINE__ . $nl;
      }
      #&add_last($precompiled_inputs, $input);
      #&add_last($precompiled_inputs, $ast_path);
    }
  }
  return $precompiled_inputs;
}
sub ordered_set_add {
  my ($ordered_set, $item, $file, $line) = @_;
  foreach my $member (@$ordered_set) {
    if ($item eq $member) {
      #printf STDERR "%s:%i: warning: item \"$item\" already present\n", $file, $line;
      return;
    }
  }
  &add_last($ordered_set, $item);
}
sub ordered_set_add_first {
  my ($ordered_set, $item, $file, $line) = @_;
  foreach my $member (@$ordered_set) {
    if ($item eq $member) {
      #printf STDERR "%s:%i: warning: item \"$item\" already present\n", $file, $line;
      return;
    }
  }
  &add_first($ordered_set, $item);
}
sub start {
  my ($argv) = @_;
  # just in case ...
}
unless (caller) {
  &start(\@ARGV);
}
1;
