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
use Cwd;
use Fcntl qw(:DEFAULT :flock);
use sort 'stable';

my $gbl_prefix;
my $gbl_platform;
my $extra;
my $build_dir;
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
  $gbl_platform = &platform("$gbl_prefix/lib/dakota/platform.yaml")
    or die "&platform(\"$gbl_prefix/lib/dakota/platform.yaml\") failed: $!" . $nl;
  $extra = &do_json("$gbl_prefix/lib/dakota/extra.json")
    or die "&do_json(\"$gbl_prefix/lib/dakota/extra.json\") failed: $!" . $nl;
  $h_ext = &var($gbl_platform, 'h_ext', undef);
  $cc_ext = &var($gbl_platform, 'cc_ext', undef);
  $o_ext =  &var($gbl_platform, 'o_ext',  undef);
  $so_ext = &var($gbl_platform, 'so_ext', undef); # default dynamic shared object/library extension
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
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

my $should_write_ctlg_files = 1;
my $want_separate_ast_pass = 1; # currently required to bootstrap dakota
my $show_outfile_info = 0;
my $global_should_echo = 0;

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
  my $result = $name =~ m=^(.*/)?(lib([.\w-]+))($so_ext((\.\d+)+)?|((\.\d+)+)?$so_ext)$=; # so-regex
  #my $libname = $2 . $so_ext;
  return $result;
}
sub is_cc_path {
  my ($arg) = @_;
  if ($arg =~ m/$cc_ext$/) {
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
      $ast = &ast_from_dk($input);
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
sub default_cmd_info {
  my $cmd_info = {};
  return $cmd_info;
}
sub target_klass_func_decls_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_src_path($cmd_info) =~ s=^$build_dir/\+/(.+?)$cc_ext$=$1-klass-func-decls.inc=r;
  return $result;
}
sub target_klass_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_src_path($cmd_info) =~ s=^$build_dir/\+/(.+?)$cc_ext$=$1-klass-func-defns.inc=r;
  return $result;
}
sub target_generic_func_decls_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_src_path($cmd_info) =~ s=^$build_dir/\+/(.+?)$cc_ext$=$1-generic-func-decls.inc=r;
  return $result;
}
sub target_generic_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $result = &target_src_path($cmd_info) =~ s=^$build_dir/\+/(.+?)$cc_ext$=$1-generic-func-defns.inc=r;
  return $result;
}
sub dk_parse {
  my ($dk_path) = @_; # string.dk
  my $ast_path = &ast_path_from_dk_path($dk_path);
  my $ast = &scalar_from_file($ast_path);
  $ast = &kw_args_translate($ast);
  return $ast;
}
sub cc_from_dk_core2 {
  my ($cmd_info, $should_echo) = @_;
  if ($should_echo) {
    print STDERR '  &cc_from_dk_core2 --output ' .
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

  my $target_inputs_ast = &target_inputs_ast($$cmd_info{'asts'}); # within cc_from_dk_core2
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
      $cc_path = "$input_dir/$input_name$cc_ext";
    }
    my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    my $inc_path = &inc_path_from_dk_path($input);
    my $h_path = $cc_path =~ s/$cc_ext$/$h_ext/r;
    $input = &canon_path($input);
    &empty_klass_defns();
    &dk_generate_cc($input, $inc_path, $target_inputs_ast);
    &src::add_extra_symbols($file_ast);
    &src::add_extra_klass_decls($file_ast);
    &src::add_extra_keywords($file_ast);
    &src::add_extra_generics($file_ast);
    my $rel_target_hdr_path = &rel_target_hdr_path($cmd_info);

    &generate_src_decl($cc_path, $file_ast, $target_inputs_ast, $rel_target_hdr_path);
    &generate_src_defn($cc_path, $file_ast, $target_inputs_ast, $rel_target_hdr_path); # rel_target_hdr_path not used
  }
  return $num_inputs;
} # cc_from_dk_core2

sub gcc_library_from_library_name {
  my ($library_name) = @_;
  # linux and darwin so-regexs are separate
  if ($library_name =~ m=^lib([.\w-]+)$so_ext((\.\d+)+)?$= ||
      $library_name =~ m=^lib([.\w-]+)((\.\d+)+)?$so_ext$=) { # so-regex
    my $library_name_base = $1;
    return "-l$library_name_base"; # hardhard: hardcoded use of -l (both gcc/clang use it)
  } else {
    return "-l$library_name";
  }
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
  my $path = $$asts[-1]; # only update the parts file ast
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
  $$cmd_info{'inputs'} = $$cmd_info{'parts.inputs'},
  &check_path($target_srcs_ast_path);
  $cmd_info = &loop_ast_from_so($cmd_info);
  $cmd_info = &loop_ast_from_inputs($cmd_info);
  &add_visibility_file($target_srcs_ast_path);

  if ($$cmd_info{'asts'}) {
    &update_kw_arg_generics($$cmd_info{'asts'});
  }
  $$cmd_info{'inputs'} = $$orig{'inputs'};
  $$cmd_info{'output'} = $$orig{'output'};
  $$cmd_info{'opts'} =   $$orig{'opts'};

  if ($ENV{'DAKOTA_CREATE_AST_ONLY'}) {
    exit 0;
  }
  return $cmd_info;
}
sub cc_files {
  my ($seq) = @_;
  my $cc_files = [];
  foreach my $cc_file (@$seq) {
    if ($cc_file =~ /$cc_ext$/) {
      &add_last($cc_files, $cc_file);
    }
  }
  return $cc_files;
}
my $root_cmd;
sub start_cmd {
  my ($cmd_info, $parts) = @_;
  $root_cmd = $cmd_info;
  $build_dir = &build_dir();
  my $cc_files = [];
  $$cmd_info{'output'} = $$cmd_info{'opts'}{'output'} if $$cmd_info{'opts'}{'output'};
  if (1) {
    my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    &make_dir_part($target_srcs_ast_path);
    $cmd_info = &update_target_srcs_ast_from_all_inputs($cmd_info, $target_srcs_ast_path); # BUGUBUG: called even when not out of date
    &set_target_srcs_ast($target_srcs_ast_path);
  }
  if ($$cmd_info{'opts'}{'target-hdr'}) {
    &gen_target_hdr($cmd_info);
  }
  if ($$cmd_info{'opts'}{'target-src'}) {
    &gen_target_src($cmd_info);
  }
  if (!$$cmd_info{'opts'}{'target-ast'} &&
      !$$cmd_info{'opts'}{'target-hdr'} &&
      !$$cmd_info{'opts'}{'target-src'}) {
    $cmd_info = &loop_cc_from_dk($cmd_info);
    $cc_files = &cc_files($$cmd_info{'inputs'});
  }
  return $cc_files;
}
sub ast_from_so {
  my ($cmd_info, $arg) = @_;
  if (!$arg) {
    $arg = $$cmd_info{'input'};
  }
  my $ctlg_path = &ctlg_path_from_so_path($arg);
  my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$ctlg_cmd{'io'} = $$cmd_info{'io'};
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
  $$ast_cmd{'io'} =  $$cmd_info{'io'};
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
    'io' =>  $$cmd_info{'io'},
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
        'io' =>  $$cmd_info{'io'},
        'output' => $ast_path,
        'inputs' => [ $input ],
      };
      &ast_from_inputs($ast_cmd);
      &ordered_set_add($ast_files, $ast_path, __FILE__, __LINE__);
    } elsif (&is_ast_path($input)) {
      &ordered_set_add($ast_files, $input, __FILE__, __LINE__);
    }
  }
  #if ($$cmd_info{'opts'}{'target-hdr'}) {
    if (0 != @$ast_files) {
      my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
      &check_path($target_srcs_ast_path);
      &ordered_set_add($$cmd_info{'asts'}, $target_srcs_ast_path, __FILE__, __LINE__);
      my $ast_cmd = {
        'opts' =>        $$cmd_info{'opts'},
        'io' =>  $$cmd_info{'io'},
        'output' => $target_srcs_ast_path,
        'inputs' => $ast_files,
      };
      &ast_from_inputs($ast_cmd); # multiple inputs
    }
  #}
  return $cmd_info;
} # loop_ast_from_inputs
sub gen_target_hdr {
  my ($cmd_info) = @_;
  my $is_defn;
  return &gen_target($cmd_info, $is_defn = 0);
}
sub gen_target_src {
  my ($cmd_info) = @_;
  my $is_defn;
  return &gen_target($cmd_info, $is_defn = 1);
}
sub gen_target {
  my ($cmd_info, $is_defn) = @_;
  #die if ! $$cmd_info{'output'};
  if ($$cmd_info{'output'}) {
    my $target_src_path = &target_src_path($cmd_info);
    my $target_hdr_path =  &target_hdr_path($cmd_info);
  }
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  &check_path($target_srcs_ast_path);
  $$cmd_info{'ast'} = $target_srcs_ast_path;
  if (!$is_defn) {
    &target_hdr_from_ast($cmd_info);
  } else {
    &target_src_from_ast($cmd_info);
  }
} # gen_target_src
sub cc_from_dk {
  my ($cmd_info, $input) = @_;
  my $ast_path = &ast_path_from_dk_path($input);
  my $num_out_of_date_infiles = 0;
  my $outfile;
  if (!&is_dk_src_path($input)) {
    $outfile = $input;
  } else {
    my $inc_path = &inc_path_from_dk_path($input);
    my $src_path = &cc_path_from_dk_path($input);
    my $h_path = &h_path_from_src_path($src_path);
    if (!$want_separate_ast_pass) {
      &check_path($ast_path);
      my $ast_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$ast_cmd{'inputs'} = [ $input ];
      $$ast_cmd{'output'} = $ast_path;
      $$ast_cmd{'io'} =  $$cmd_info{'io'};
      $num_out_of_date_infiles = &ast_from_inputs($ast_cmd);
      &ordered_set_add($$cmd_info{'asts'}, $ast_path, __FILE__, __LINE__);
    }
    my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$cc_cmd{'inputs'} = [ $input ];
    $$cc_cmd{'output'} = $src_path;
    $$cc_cmd{'asts'} = $$cmd_info{'asts'};
    $$cc_cmd{'io'} =  $$cmd_info{'io'};
    $num_out_of_date_infiles = &cc_from_dk_core1($cc_cmd);
    if ($num_out_of_date_infiles) {
      my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
    }
    $outfile = $$cc_cmd{'output'};
    &dakota_io_add($$cmd_info{'io'}, 'precompile', $input, $outfile);
  }
  return $outfile;
} # cc_from_dk
sub loop_cc_from_dk {
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
      &add_last($outfiles, &cc_from_dk($cmd_info, $input));
    } elsif (&is_cc_path($input)) {
      ###
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
} # loop_cc_from_dk
sub cc_from_dk_core1 {
  my ($cmd_info) = @_;
  my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$cc_cmd{'io'} =  $$cmd_info{'io'};
  $$cc_cmd{'cmd'} = '&cc_from_dk_core2';
  $$cc_cmd{'asts'} = $$cmd_info{'asts'};
  $$cc_cmd{'output'} = $$cmd_info{'output'};
  $$cc_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  return &outfile_from_infiles($cc_cmd, $should_echo = 0);
}
sub target_hdr_from_ast {
  my ($cmd_info) = @_;
  my $is_defn;
  return &target_from_ast($cmd_info, $is_defn = 0);
}
sub target_src_from_ast {
  my ($cmd_info) = @_;
  my $is_defn;
  return &target_from_ast($cmd_info, $is_defn = 1);
}
sub target_from_ast {
  my ($cmd_info, $is_defn) = @_;
  die if ! defined $$cmd_info{'asts'} || 0 == @{$$cmd_info{'asts'}};
  my $target_srcs_ast_path = &target_srcs_ast_path($cmd_info);
  my $target_src_path = &target_src_path($cmd_info);
  my $target_hdr_path =  &target_hdr_path($cmd_info);
  &check_path($target_srcs_ast_path);

  if ($is_defn) {
    if ($$cmd_info{'opts'}{'target-src'}) {
      return if !&is_out_of_date($target_srcs_ast_path, $target_src_path);
    }
  } elsif ($$cmd_info{'opts'}{'target-hdr'}) {
    return if !&is_out_of_date($target_srcs_ast_path, $target_hdr_path);
  }
  &make_dir_part($target_src_path, $global_should_echo);
  my ($path, $file_basename, $target_srcs_ast) = ($target_src_path, $target_src_path, undef);
  $path =~ s|/[^/]*$||;
  $file_basename =~ s|^[^/]*/||;       # strip off leading $build_dir/
  # $target_inputs_ast not used, called for side-effect
  my $target_inputs_ast = &target_inputs_ast($$cmd_info{'asts'}); # within target_src_from_ast
  $target_srcs_ast = &scalar_from_file($target_srcs_ast_path);
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
    &generate_target_defn($target_src_path, $target_srcs_ast, $target_inputs_ast);
    &dakota_io_assign($$cmd_info{'io'}, 'target-src', $target_src_path);
  } else {
    &generate_target_decl($target_hdr_path, $target_srcs_ast, $target_inputs_ast);
  }
}
sub verbose_exec_cmd_info {
  my ($cmd_info) = @_;
  my $argv = &argv_from_cmd_info($cmd_info);
  my $exit_val = &verbose_exec($argv);
  return $exit_val;
}
sub outfile_from_infiles {
  my ($cmd_info, $should_echo) = @_;
  my $outfile = $$cmd_info{'output'};
  &make_dir_part($outfile, $should_echo);
  if ($outfile =~ m|^$build_dir/$build_dir/|) { die "found double build-dir/build-dir: $outfile"; } # likely a double $build_dir prepend
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
    } elsif ('&cc_from_dk_core2' eq $$cmd_info{'cmd'}) {
      $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
      delete $$cmd_info{'output'};
      delete $$cmd_info{'cmd'};
      delete $$cmd_info{'cmd-flags'};
      &cc_from_dk_core2($cmd_info, $global_should_echo || $should_echo);
    } else {
      my $exit_val = &verbose_exec_cmd_info($cmd_info); # dakota-catalog
      exit 1 if $exit_val;
    }
  }
  return $num_out_of_date_infiles;
} # outfile_from_infiles
sub ctlg_from_so {
  my ($cmd_info) = @_;
  my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$ctlg_cmd{'io'} =  $$cmd_info{'io'};

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
  $$ctlg_cmd{'output'} = $$cmd_info{'output'};
  $$ctlg_cmd{'output-directory'} = $$cmd_info{'output-directory'};

  $$ctlg_cmd{'inputs'} = &precompiled_inputs($cmd_info);
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
