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

package dakota::dakota;

use strict;
use warnings;
use sort 'stable';

my $gbl_prefix;
my $gbl_compiler;
my $extra;
my $objdir;
my $hh_ext;
my $cc_ext;
my $o_ext;
my $so_ext;
my $nl = "\n";

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
  use dakota::util;
  use dakota::parse;
  use dakota::generate;
  $gbl_compiler = do "$gbl_prefix/lib/dakota/compiler/command-line.json"
    or die "do $gbl_prefix/lib/dakota/compiler/command-line.json failed: $!\n";
  my $platform = do "$gbl_prefix/lib/dakota/platform.json"
    or die "do $gbl_prefix/lib/dakota/platform.json failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $extra = do "$gbl_prefix/lib/dakota/extra.json"
    or die "do $gbl_prefix/lib/dakota/extra.json failed: $!\n";
  $hh_ext = &dakota::util::var($gbl_compiler, 'hh_ext', 'hh');
  $cc_ext = &dakota::util::var($gbl_compiler, 'cc_ext', 'cc');
  $o_ext =  &dakota::util::var($gbl_compiler, 'o_ext',  'o');
  $so_ext = &dakota::util::var($gbl_compiler, 'so_ext', 'so'); # default dynamic shared object/library extension
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 is_dk_path
                 is_o_path
                 rt_cc_path
                 rel_rt_hh_path
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
my $want_separate_rep_pass = 1; # currently required to bootstrap dakota
my $want_separate_precompile_pass = 0;
my $show_outfile_info = 0;
my $global_should_echo = 0;
my $exit_status = 0;
my $dk_exe_type = undef;

my $cxx_compile_flags = &dakota::util::var($gbl_compiler, 'CXX_COMPILE_FLAGS', [ '--compile', '--PIC' ]); # or -fPIC
my $cxx_output_flags =  &dakota::util::var($gbl_compiler, 'CXX_OUTPUT_FLAGS',  '--output');
my $cxx_shared_flags =  &dakota::util::var($gbl_compiler, 'CXX_SHARED_FLAGS',  '--shared');
my $cxx_dynamic_flags = &dakota::util::var($gbl_compiler, 'CXX_DYNAMIC_FLAGS', '--dynamic');

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();
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
sub is_dk_path {
  my ($arg) = @_;
  if ($arg =~ m/\.dk$/) {
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
sub is_rep_input_path { # dk, ctlg, or so
  my ($arg) = @_;
  if (&is_so_path($arg) || &is_dk_src_path($arg)) {
    return 1;
  } else {
    return 0;
  }
}
sub is_rep_path { # json
  my ($arg) = @_;
  if ($arg =~ m/\.json$/) {
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
sub loop_merged_rep_from_inputs {
  my ($cmd_info, $should_echo) = @_; 
  if ($should_echo) {
    print STDERR '  &loop_merged_rep_from_inputs --output ' .
      $$cmd_info{'opts'}{'output'} . ' ' . join(' ', @{$$cmd_info{'inputs'}}) . $nl;
  }
  &dakota::parse::init_rep_from_inputs_vars($cmd_info);
  my $rep_files = [];
  if ($$cmd_info{'reps'}) {
    $rep_files = $$cmd_info{'reps'};
  }
  my $root;
  my $root_json_path;
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_src_path($input)) {
      $root = &dakota::parse::rep_tree_from_dk_path($input);
      my $json_path;
      if (&is_dk_path($input)) {
        $json_path = &json_path_from_dk_path($input);
      } elsif (&is_ctlg_path($input)) {
        $json_path = &json_path_from_ctlg_path($input);
      } else {
        die;
      }
      &check_path($json_path);
      $root_json_path = $json_path;
      &dakota::util::add_last($rep_files, $json_path); # _from_dk_src_path
    } elsif (&is_rep_path($input)) {
      $root = &scalar_from_file($input);
      $root_json_path = $input;
      &dakota::util::add_last($rep_files, $input);
    } else {
      die __FILE__, ":", __LINE__, ": ERROR\n";
    }
  }
  if ($$cmd_info{'opts'}{'output'} && !exists $$cmd_info{'opts'}{'ctlg'}) {
    if (1 == @{$$cmd_info{'inputs'}}) {
      &dakota::parse::scalar_to_file($$cmd_info{'opts'}{'output'}, $root);
    } elsif (1 < @{$$cmd_info{'inputs'}}) {
      my $rep = &rep_merge($rep_files);
      &dakota::parse::scalar_to_file($$cmd_info{'opts'}{'output'}, $rep);
      &project_io_add($cmd_info, $rep_files, $$cmd_info{'opts'}{'output'});
    }
  }
} # loop_merged_rep_from_inputs
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
sub project_io_add {
  my ($cmd_info, $input, $depend) = @_;
  die if &is_array($input) && &is_array($depend);
  my $should_write = 0;
  my $project_io = &scalar_from_file($$cmd_info{'project.io'});

  if (&is_array($input)) {
    $depend = &canon_path($depend);
    foreach my $in (@$input) {
      $in = &canon_path($in);
      if (!exists $$project_io{'all'}{$in}{$depend}) {
        $$project_io{'all'}{$in}{$depend} = 1;
        $should_write = 1;
      }
    }
  } elsif (&is_array($depend)) {
    $input = &canon_path($input);
    foreach my $dp (@$depend) {
      $dp = &canon_path($dp);
      if (!exists $$project_io{'all'}{$input}{$dp}) {
        $$project_io{'all'}{$input}{$dp} = 1;
        $should_write = 1;
      }
    }
  } else {
    $input = &canon_path($input);
    $depend = &canon_path($depend);
    if (!exists $$project_io{'all'}{$input}{$depend}) {
      $$project_io{'all'}{$input}{$depend} = 1;
      $should_write = 1;
    }
  }
  if ($should_write) {
    &scalar_from_file($$cmd_info{'project.io'}, $project_io);
  }
}
sub add_visibility_file {
  my ($arg) = @_;
  #print STDERR "&add_visibility_file(path=\"$arg\")\n";
  my $root = &scalar_from_file($arg);
  &add_visibility($root);
  &dakota::parse::scalar_to_file($arg, $root);
}
sub add_visibility {
  my ($root) = @_;
  my $debug = 0;
  my $names = [keys %{$$root{'modules'}}];
  foreach my $name (@$names) {
    my $tbl = $$root{'modules'}{$name}{'export'};
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
        if ($$root{'klasses'}{$klass_name} &&
            $$root{'klasses'}{$klass_name}{'slots'} &&
            $$root{'klasses'}{$klass_name}{'slots'}{'module'} eq $name) {
          $$root{'klasses'}{$klass_name}{'slots'}{'exported?'} = __FILE__ . '::' . __LINE__;
        }
      } elsif ($str =~ /^((klass|trait)\s+)?($rid)$/) {
        my ($klass_type, $klass_name) = ($2, $3);
        # klass/trait
        if ($debug) { print STDERR "klass-type: <$klass_type>:        klass-name: <$klass_name>\n"; }
        if ($$root{'klasses'}{$klass_name} &&
            $$root{'klasses'}{$klass_name}{'module'} &&
            $$root{'klasses'}{$klass_name}{'module'} eq $name) {
          $$root{'klasses'}{$klass_name}{'exported?'} = __FILE__ . '::' . __LINE__;
        }
        if ($$root{'traits'}{$klass_name}) {
          $$root{'traits'}{$klass_name}{'exported?'} = __FILE__ . '::' . __LINE__;
        }
      } elsif ($str =~ /^((klass|trait)\s+)?($rid)::($msig)$/) {
        my ($klass_type, $klass_name, $method_name) = ($2, $3, $4);
        # klass/trait method
        if ($debug) { print STDERR "$klass_type method $klass_name:$method_name\n"; }
        foreach my $constructs ('klasses', 'traits') {
          if ($$root{$constructs}{$klass_name} &&
              $$root{$constructs}{$klass_name}{'module'} eq $name) {
            foreach my $method_type ('slots-methods', 'methods') {
              if ($debug) { print STDERR &Dumper($$root{$constructs}{$klass_name}); }
              while (my ($sig, $scope) = each (%{$$root{$constructs}{$klass_name}{$method_type}})) {
                my $sig_min = &sig1($scope);
                if ($method_name =~ m/\(\)$/) {
                  $sig_min =~ s/\(.*?\)$/\(\)/;
                }
                if ($debug) { print STDERR "$sig == $method_name\n"; }
                if ($debug) { print STDERR "$sig_min == $method_name\n"; }
                if ($sig_min eq $method_name) {
                  if ($debug) { print STDERR "$sig == $method_name\n"; }
                  if ($debug) { print STDERR "$sig_min == $method_name\n"; }
                  $$scope{'exported?'} = __FILE__ . '::' . __LINE__;
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
sub nrt::add_extra_generics {
  my ($file) = @_;
  my $generics = $$extra{'nrt_extra_generics'};
  foreach my $generic (sort keys %$generics) {
    &add_generic($file, $generic);
  }
}
sub nrt::add_extra_keywords {
  my ($file) = @_;
  my $keywords = $$extra{'nrt_extra_keywords'};
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
sub rt::add_extra_keywords {
  my ($file) = @_;
  my $keywords = $$extra{'rt_extra_keywords'};
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
###
sub nrt::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = $$extra{'nrt_extra_klass_decls'};
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
sub rt::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = $$extra{'rt_extra_klass_decls'};
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
###
sub nrt::add_extra_symbols {
  my ($file) = @_;
  my $symbols = $$extra{'nrt_extra_symbols'};
  foreach my $symbol (sort keys %$symbols) {
    &dakota::parse::add_symbol($file, $symbol);
  }
}
sub rt::add_extra_symbols {
  my ($file) = @_;
  my $symbols = $$extra{'rt_extra_symbols'};
  foreach my $symbol (sort keys %$symbols) {
    &dakota::parse::add_symbol($file, $symbol);
  }
}
sub sig1 {
  my ($scope) = @_;
  my $result = '';
  $result .= &ct($$scope{'name'});
  $result .= '(';
  $result .= &ct($$scope{'parameter-types'}[0]);
  $result .= ')';
  return $result;
}
sub rt_json_path {
  my ($cmd_info) = @_;
  my $rt_json_path;
  if (&is_so_path($$cmd_info{'project.output'})) {
    $rt_json_path = &rt_json_path_from_so_path($$cmd_info{'project.output'}); # should be from_so_path
  } else {
    $rt_json_path = &rt_json_path_from_any_path($$cmd_info{'project.output'}); # _from_exe_path
  }
  return $rt_json_path;
}
sub rt_cc_path {
  my ($cmd_info) = @_;
  my $rt_cc_path;
  if (&is_so_path($$cmd_info{'project.output'})) {
    $rt_cc_path = &rt_cc_path_from_so_path($$cmd_info{'project.output'});
  } else {
    $rt_cc_path = &rt_cc_path_from_any_path($$cmd_info{'project.output'});
  }
  return $rt_cc_path;
}
sub rel_rt_hh_path {
  my ($cmd_info) = @_;
  my $rt_cc_path = &rt_cc_path($cmd_info);
  my $rel_rt_hh_path = $rt_cc_path =~ s=^$objdir/(.+?)\.$cc_ext$=$1.$hh_ext=r;
  return $rel_rt_hh_path;
}
sub loop_cc_from_dk {
  my ($cmd_info, $should_echo) = @_;
  if ($should_echo) {
    print STDERR '  &loop_cc_from_dk --output ' .
      $$cmd_info{'opts'}{'output'} . ' ' . join(' ', @{$$cmd_info{'inputs'}}) . $nl;
  }
  &dakota::parse::init_cc_from_dk_vars($cmd_info);

  my $inputs = [];
  my $rep;
  if ($$cmd_info{'reps'}) {
    $rep = $$cmd_info{'reps'};
  } else {
    $rep = [];
  }
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_rep_path($input)) {
      &dakota::util::add_last($rep, $input);
    } else {
      &dakota::util::add_last($inputs, $input);
    }
  }
  $$cmd_info{'reps'} = $rep;
  $$cmd_info{'inputs'} = $inputs;

  my $global_rep = &init_global_rep($$cmd_info{'reps'}); # within loop_cc_from_dk
  my $num_inputs = @{$$cmd_info{'inputs'}};
  if (0 == $num_inputs) {
    die "$0: error: arguments are requried\n";
  }
  my $project_io = &scalar_from_file($$cmd_info{'project.io'});

  foreach my $input (@{$$cmd_info{'inputs'}}) {
    my $json_path;
    if (&is_so_path($input)) {
      my $ctlg_path = &ctlg_path_from_so_path($input);
      $json_path = &json_path_from_ctlg_path($ctlg_path);
      &check_path($json_path);
    } elsif (&is_dk_src_path($input)) {
      $json_path = &json_path_from_dk_path($input);
      &check_path($json_path);
    } else {
      #print "skipping $input, line=" . __LINE__ . $nl;
    }

    my ($input_dir, $input_name, $input_ext) = &split_path($input, $id);
    my $file = &dakota::generate::dk_parse("$input_name.dk");
    my $cc_path;
    if ($$cmd_info{'opts'}{'output'}) {
      $cc_path = $$cmd_info{'opts'}{'output'};
    } else {
      $cc_path = "$input_name.$cc_ext";
    }
    my $rt_json_path = &rt_json_path($cmd_info);
    my $user_dk_path = &user_path_from_any_path($input);
    my $hh_path = $cc_path =~ s/\.$cc_ext$/\.$hh_ext/r;
    $input = &canon_path($input);
    $$project_io{'all'}{$input}{$user_dk_path} = 1;
    $$project_io{'all'}{$rt_json_path}{$user_dk_path} = 1;
    $$project_io{'all'}{$rt_json_path}{$hh_path} = 1;
    $$project_io{'all'}{$rt_json_path}{$cc_path} = 1;
    &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);

    &dakota::generate::empty_klass_defns();
    &dakota::generate::dk_generate_cc($input_name, $user_dk_path, $global_rep);
    &nrt::add_extra_symbols($file);
    &nrt::add_extra_klass_decls($file);
    &nrt::add_extra_keywords($file);
    &nrt::add_extra_generics($file);
    my $rel_rt_hh_path = &rel_rt_hh_path($cmd_info);

    if (0) {
      #  for each translation unit create links to the linkage unit header file
    } else {
      &dakota::generate::generate_nrt_decl($cc_path, $file, $global_rep, $rel_rt_hh_path);
    }
    &dakota::generate::generate_nrt_defn($cc_path, $file, $global_rep, $rel_rt_hh_path); # rel_rt_hh not used
  }
  return $num_inputs;
} # loop_cc_from_dk

sub gcc_library_from_library_name {
  my ($library_name) = @_;
  if ($library_name =~ m=^lib([.\w-]+)\.$so_ext((\.\d+)+)?$= ||
      $library_name =~ m=^lib([.\w-]+)((\.\d+)+)?\.$so_ext$=) { # so-regex
    my $library_name_base = $1;
    return "-l$library_name_base"; # hardhard: hardcoded use of -l (both gcc/clang use it)
  } else {
    print STDERR  "warning: $library_name does not look like a library name.\n";
    return "--library $library_name";
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
      $result .= "--library-directory=$library_directory --for-linker -rpath=$library_directory ";
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
  my $for_linker = &dakota::util::var($gbl_compiler, 'CXX_FOR_LINKER_FLAGS', [ '--for-linker' ]);
  my $result = ' ' . $for_linker . '=' . $tkns;
  return $result;
}
sub update_kw_args_generics {
  my ($reps) = @_;
  my $kw_args_generics = {};
  foreach my $path (@$reps) {
    my $rep = &scalar_from_file($path);
    my $tbl = $$rep{'kw-args-generics'};
    if ($tbl) {
      while (my ($name, $params_tbl) = each(%$tbl)) {
        while (my ($params_str, $params) = each(%$params_tbl)) {
          $$kw_args_generics{$name}{$params_str} = $params;
        }
      }
    }
  }
  my $path = $$reps[-1]; # only update the project file rep
  my $rep = &scalar_from_file($path);
  $$rep{'kw-args-generics'} = $kw_args_generics;
  &scalar_to_file($path, $rep);
}
sub update_rep_from_all_inputs {
  my ($cmd_info) = @_;
  my $start_time = time;
  my $orig = { 'inputs' => $$cmd_info{'inputs'},
               'output' => $$cmd_info{'output'},
               'opts' =>   &deep_copy($$cmd_info{'opts'}),
             };
  $$cmd_info{'inputs'} = $$cmd_info{'project.inputs'},
  $$cmd_info{'output'} = $$cmd_info{'project.output'},
  $$cmd_info{'opts'}{'echo-inputs'} = 0;
  $$cmd_info{'opts'}{'silent'} = 1;
  delete $$cmd_info{'opts'}{'compile'};
  my $rt_json_path = &rt_json_path($cmd_info);
  &check_path($rt_json_path);
  if (&is_debug()) {
    print "creating $rt_json_path" . &pann(__FILE__, __LINE__) . $nl;
  }
  $cmd_info = &loop_rep_from_so($cmd_info);
  $cmd_info = &loop_rep_from_inputs($cmd_info);
  die if $$cmd_info{'reps'}[-1] ne $rt_json_path; # assert
  &add_visibility_file($rt_json_path);

  &update_kw_args_generics($$cmd_info{'reps'});
  $$cmd_info{'inputs'} = $$orig{'inputs'};
  $$cmd_info{'output'} = $$orig{'output'};
  $$cmd_info{'opts'} =   $$orig{'opts'};

  if (&is_debug()) {
    my $end_time = time;
    my $elapsed_time = $end_time - $start_time;
    print "creating $rt_json_path ... done ($elapsed_time secs)" . &pann(__FILE__, __LINE__) . $nl;
  }
  if ($ENV{'DAKOTA_CREATE_REP_ONLY'}) {
    exit 0;
  }
  return $cmd_info;
}
my $root_cmd;
sub start_cmd {
  my ($cmd_info) = @_;
  $objdir = &dakota::util::objdir();
  $cmd_info = &update_rep_from_all_inputs($cmd_info);
  my $rt_json_path = &rt_json_path($cmd_info);
  &set_global_project_rep($rt_json_path);
  $root_cmd = $cmd_info;

  if (!$$cmd_info{'opts'}{'compiler'}) {
    my $cxx = &dakota::util::var($gbl_compiler, 'CXX', 'g++');
    $$cmd_info{'opts'}{'compiler'} = $cxx;
  }
  if (!$$cmd_info{'opts'}{'compiler-flags'}) {
    my $cxxflags =       &dakota::util::var($gbl_compiler, 'CXXFLAGS', [ '-std=c++11', '--visibility=hidden' ]);
    my $extra_cxxflags = &dakota::util::var($gbl_compiler, 'EXTRA_CXXFLAGS', '');
    $$cmd_info{'opts'}{'compiler-flags'} = $cxxflags . ' ' . $extra_cxxflags;
  }
  my $ld_soname_flags =    &dakota::util::var($gbl_compiler, 'LD_SONAME_FLAGS', '-soname');
  my $no_undefined_flags = &dakota::util::var($gbl_compiler, 'LD_NO_UNDEFINED_FLAGS', '--no-undefined');
  if ($$cmd_info{'opts'}{'compile'}) {
    $dk_exe_type = undef;
  } elsif ($$cmd_info{'opts'}{'shared'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
      $cxx_shared_flags .= &for_linker($ld_soname_flags . '=' . $$cmd_info{'opts'}{'soname'});
    }
    $cxx_shared_flags .= &for_linker($no_undefined_flags);
    $dk_exe_type = 'exe-type::k_lib';
  } elsif ($$cmd_info{'opts'}{'dynamic'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
      $cxx_shared_flags .= &for_linker($ld_soname_flags . '=' . $$cmd_info{'opts'}{'soname'});
    }
    $cxx_shared_flags .= &for_linker($no_undefined_flags);
    $dk_exe_type = 'exe-type::k_lib';
  } elsif (!$$cmd_info{'opts'}{'compile'}
	   && !$$cmd_info{'opts'}{'shared'}
	   && !$$cmd_info{'opts'}{'dynamic'}) {
    $dk_exe_type = 'exe-type::k_exe';
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  $$cmd_info{'output'} = $$cmd_info{'opts'}{'output'};
  if ($$cmd_info{'output'}) {
    if ($ENV{'DKT_PRECOMPILE'}) {
      my $rt_cc_path = &rt_cc_path($cmd_info);
      if (&is_debug()) {
        print "creating $rt_cc_path" . &pann(__FILE__, __LINE__) . $nl;
      }
    } else {
      if (&is_debug()) {
        print "creating $$cmd_info{'output'}" . &pann(__FILE__, __LINE__) . $nl;
      }
    }
  }
  if ($should_replace_library_path_with_lib_opts) {
    $$cmd_info{'inputs-tbl'} = &inputs_tbl($$cmd_info{'inputs'});
  }
  if ($ENV{'DKT_GENERATE_RUNTIME_FIRST'}) {
    # generate the single (but slow) runtime .o, then the user .o files
    # this might be useful for distributed building (initiating the building of the slowest first
    # or for testing runtime code generation
    # also, this might be useful if the runtime .h file is being used rather than generating a
    # translation unit specific .h file (like in the case of inline funcs)
    if (!$$cmd_info{'opts'}{'compile'}) {
      my $is_exe = !defined $$cmd_info{'opts'}{'shared'};
      &gen_rt_o($cmd_info, $is_exe);
    }
    $cmd_info = &loop_o_from_dk($cmd_info);
  } else {
     # generate user .o files first, then the single (but slow) runtime .o
    $cmd_info = &loop_o_from_dk($cmd_info);
    if (!$$cmd_info{'opts'}{'compile'}) {
      my $is_exe = !defined $$cmd_info{'opts'}{'shared'};
      &gen_rt_o($cmd_info, $is_exe);
    }
  }
  if (!$ENV{'DKT_PRECOMPILE'}) {
    if ($$cmd_info{'opts'}{'compile'}) {
      if ($want_separate_precompile_pass) {
        &o_from_cc($cmd_info, &compile_opts_path(), $cxx_compile_flags);
      }
    } elsif ($$cmd_info{'opts'}{'shared'}) {
      &linked_output_from_o($cmd_info, &link_so_opts_path(), $cxx_shared_flags);
    } elsif ($$cmd_info{'opts'}{'dynamic'}) {
      &linked_output_from_o($cmd_info, &link_dso_opts_path(), $cxx_dynamic_flags);
    } elsif (!$$cmd_info{'opts'}{'compile'} &&
             !$$cmd_info{'opts'}{'shared'}  &&
             !$$cmd_info{'opts'}{'dynamic'}) {
      my $mode_flags;
      &linked_output_from_o($cmd_info, &link_exe_opts_path(), $mode_flags = undef);
    } else {
      die __FILE__, ":", __LINE__, ": error:\n";
    }
  }
  return $exit_status;
}
sub rep_from_so {
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
  my $json_path = &json_path_from_ctlg_path($ctlg_path);
  &check_path($json_path);
  &ordered_set_add($$cmd_info{'reps'}, $json_path, __FILE__, __LINE__);
  my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$rep_cmd{'output'} = $json_path;
  $$rep_cmd{'inputs'} = [ $ctlg_path ];
  $$rep_cmd{'project.io'} =  $$cmd_info{'project.io'};
  &rep_from_inputs($rep_cmd);
  if (!$should_write_ctlg_files) {
    #unlink $ctlg_path;
  }
}
sub loop_rep_from_so {
  my ($cmd_info) = @_;
  my $project_io = &scalar_from_file($$cmd_info{'project.io'});
  my $rt_json_path = &rt_json_path($cmd_info);
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_so_path($input)) {
      &rep_from_so($cmd_info, $input);
      my $ctlg_path = &ctlg_path_from_so_path($input);
      my $json_path = &json_path_from_ctlg_path($ctlg_path);
      $input = &canon_path($input);
      $$project_io{'all'}{$input}{$ctlg_path} = 1;
      $$project_io{'all'}{$ctlg_path}{$json_path} = 1;
      $$project_io{'all'}{$json_path}{$rt_json_path} = 1;
    }
  }
  &scalar_to_file($$cmd_info{'project.io'}, $project_io);
  return $cmd_info;
} # loop_rep_from_so
sub check_path {
  my ($path) = @_;
  die if $path =~ m=^obj/obj/=;
  die if $path =~ m=^obj/-{rt|user}/obj/=;
}
sub rep_from_inputs {
  my ($cmd_info) = @_;
  my $rep_cmd = {
    'cmd' =>         '&loop_merged_rep_from_inputs',
    'opts' =>        $$cmd_info{'opts'},
    'output' =>      $$cmd_info{'output'},
    'inputs' =>      $$cmd_info{'inputs'},
    'project.io' =>  $$cmd_info{'project.io'},
    'project.output' =>  $$cmd_info{'project.output'},
  };
  my $should_echo;
  my $result = &outfile_from_infiles($rep_cmd, $should_echo = 0);
  if ($result) {
    if (0 != @{$$rep_cmd{'reps'} ||= []}) {
      my $rt_json_path = &rt_json_path($cmd_info);
      &project_io_add($cmd_info, $$rep_cmd{'reps'}, $rt_json_path);
    }
    foreach my $input (@{$$rep_cmd{'inputs'}}) {
      if (&is_so_path($input)) {
        my $ctlg_path = &ctlg_path_from_so_path($input);
        my $json_path = &json_path_from_ctlg_path($ctlg_path);
        &check_path($json_path);
        &project_io_add($cmd_info, $input, $ctlg_path);
        &project_io_add($cmd_info, $ctlg_path, $json_path);
      } elsif (&is_dk_path($input)) {
        my $json_path = &json_path_from_dk_path($input);
        &check_path($json_path);
        &project_io_add($cmd_info, $input, $json_path);
      } elsif (&is_ctlg_path($input)) {
        my $json_path = &json_path_from_ctlg_path($input);
        &check_path($json_path);
        &project_io_add($cmd_info, $input, $json_path);
      } else {
        #print "skipping $input, line=" . __LINE__ . $nl;
      }
    }
  }
  return $result;
}
sub loop_rep_from_inputs {
  my ($cmd_info) = @_;
  my $rep_files = [];
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_src_path($input)) {
      my $json_path = &json_path_from_dk_path($input);
      &check_path($json_path);
      my $rep_cmd = {
        'opts' =>        $$cmd_info{'opts'},
        'project.io' =>  $$cmd_info{'project.io'},
        'output' => $json_path,
        'inputs' => [ $input ],
      };
      &rep_from_inputs($rep_cmd);
      &ordered_set_add($rep_files, $json_path, __FILE__, __LINE__);
    } elsif (&is_rep_path($input)) {
      &ordered_set_add($rep_files, $input, __FILE__, __LINE__);
    }
  }
  die if ! $$cmd_info{'output'};
  if ($$cmd_info{'output'} && !$$cmd_info{'opts'}{'compile'}) {
    if (0 != @$rep_files) {
      my $rt_json_path = &rt_json_path($cmd_info);
      &check_path($rt_json_path);
      &ordered_set_add($$cmd_info{'reps'}, $rt_json_path, __FILE__, __LINE__);
      my $rep_cmd = {
        'opts' =>        $$cmd_info{'opts'},
        'project.io' =>  $$cmd_info{'project.io'},
        'output' => $rt_json_path,
        'inputs' => $rep_files,
      };
      &rep_from_inputs($rep_cmd); # multiple inputs
    }
  }
  return $cmd_info;
} # loop_rep_from_inputs
sub gen_rt_o {
  my ($cmd_info, $is_exe) = @_;
  die if ! $$cmd_info{'output'};
  if ($$cmd_info{'output'}) {
    my $rt_cc_path = &rt_cc_path($cmd_info);
    if ($$cmd_info{'opts'}{'echo-inputs'}) {
      my $rt_dk_path = &dk_path_from_cc_path($rt_cc_path);
      print $rt_dk_path . $nl;
    }
    if (&is_debug()) {
      if ($ENV{'DKT_PRECOMPILE'}) {
        print "  creating $rt_cc_path" . &pann(__FILE__, __LINE__) . $nl;
      } else {
        print "  creating $$cmd_info{'output'}" . &pann(__FILE__, __LINE__) . $nl;
      }
    }
  }
  my $rt_json_path = &rt_json_path($cmd_info);
  &check_path($rt_json_path);
  $$cmd_info{'rep'} = $rt_json_path;
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
  &rt_o_from_json($cmd_info, $other, $is_exe);
}
sub o_from_dk {
  my ($cmd_info, $input) = @_;
  my $json_path = &json_path_from_dk_path($input);
  my $num_out_of_date_infiles = 0;
  my $outfile;
  if (!&is_dk_src_path($input)) {
    if ($$cmd_info{'opts'}{'echo-inputs'}) {
      #print $input . $nl; # dk_path
    }
    $outfile = $input;
  } else {
    my $user_dk_path = &user_path_from_any_path($input);
    my $o_path;
    if ($$cmd_info{'output'} && &is_o_path($$cmd_info{'output'})) {
      $o_path = $$cmd_info{'output'};
    } else {
      $o_path =  &o_path_from_dk_path($input);
    }
    my $is_out_of_date = &is_out_of_date($input, $o_path);
    if ($is_out_of_date && $$cmd_info{'opts'}{'echo-inputs'}) {
      print $input . $nl;
    }
    if ($is_out_of_date && !$$cmd_info{'opts'}{'silent'}) {
      print $o_path . $nl;
    }
    my $src_path = &src_path_from_o_path($o_path); # reverse dependency
    my $hh_path = &hh_path_from_src_path($src_path);
    if (&is_debug()) {
      if ($ENV{'DKT_PRECOMPILE'}) {
        print "  creating $src_path" . &pann(__FILE__, __LINE__) . $nl;
      } else {
        print "  creating $o_path" . &pann(__FILE__, __LINE__) . $nl;
      }
    }
    if (!$want_separate_rep_pass) {
      &check_path($json_path);
      my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$rep_cmd{'inputs'} = [ $input ];
      $$rep_cmd{'output'} = $json_path;
      $$rep_cmd{'project.io'} =  $$cmd_info{'project.io'};
      $num_out_of_date_infiles = &rep_from_inputs($rep_cmd);
      if ($num_out_of_date_infiles) {
        &project_io_add($cmd_info, $input, $json_path);
      }
      &ordered_set_add($$cmd_info{'reps'}, $json_path, __FILE__, __LINE__);
    }
    my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$cc_cmd{'inputs'} = [ $input ];
    $$cc_cmd{'output'} = $src_path;
    $$cc_cmd{'reps'} = $$cmd_info{'reps'};
    $$cc_cmd{'project.io'} =  $$cmd_info{'project.io'};
    $$cc_cmd{'project.output'} = $$cmd_info{'project.output'};
    $num_out_of_date_infiles = &cc_from_dk($cc_cmd);
    if ($num_out_of_date_infiles) {
      my $rt_json_path = &rt_json_path($cmd_info);
      my $project_io = &scalar_from_file($$cmd_info{'project.io'});
      if (!$$project_io{'all'}{$rt_json_path}{$src_path}) {
        $$project_io{'all'}{$rt_json_path}{$src_path} = 1;
        $$project_io{'all'}{$rt_json_path}{$hh_path} = 1;
        &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);
      }
    }
    if ($ENV{'DKT_PRECOMPILE'}) {
      $outfile = $$cc_cmd{'output'};
    } else {
      my $o_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$o_cmd{'inputs'} = [ $src_path ];
      $$o_cmd{'output'} = $o_path;
      $$o_cmd{'project.io'} =  $$cmd_info{'project.io'};
      delete $$o_cmd{'opts'}{'output'};
      $num_out_of_date_infiles = &o_from_cc($o_cmd, &compile_opts_path(), $cxx_compile_flags);

      my $project_io = &scalar_from_file($$cmd_info{'project.io'});
      $$project_io{'compile'}{$input} = $o_path;
      &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);

      if ($num_out_of_date_infiles) {
        my $project_io = &scalar_from_file($$cmd_info{'project.io'});
        $$project_io{'all'}{$src_path}{$o_path} = 1;
        $$project_io{'all'}{$hh_path}{$o_path} = 1;
        $$project_io{'all'}{$user_dk_path}{$o_path} = 1;
        $$project_io{'all'}{$json_path}{$src_path} = 1;
        $$project_io{'all'}{$json_path}{$hh_path} = 1;
        &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);
      }
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
      push @$outfiles, &o_from_dk($cmd_info, $input);
    } else {
      push @$outfiles, $input;
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
  $$cc_cmd{'project.output'} = $$cmd_info{'project.output'};
  $$cc_cmd{'cmd'} = '&loop_cc_from_dk';
  $$cc_cmd{'reps'} = $$cmd_info{'reps'};
  $$cc_cmd{'output'} = $$cmd_info{'output'};
  $$cc_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  return &outfile_from_infiles($cc_cmd, $should_echo = 0);
}
sub common_opts_path {
  return $objdir . '/cxx-common.opts';
}
sub compile_opts_path {
  return $objdir . '/cxx-compile.opts';
}
sub link_so_opts_path {
  return $objdir . '/cxx-link-so.opts';
}
sub link_exe_opts_path {
  return $objdir . '/cxx-link-exe.opts';
}
sub o_from_cc {
  my ($cmd_info, $opts_path, $mode_flags) = @_;
  open(my $fh1, '>', &common_opts_path());
  my $opts = $$cmd_info{'opts'}{'compiler-flags'};
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  print $fh1 $opts . $nl;
  close($fh1);
  $opts =
    $mode_flags . $nl .
      '@' . &common_opts_path() . $nl;
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  open(my $fh2, '>', $opts_path);
  print $fh2 $opts . $nl;
  close($fh2);
  my $o_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$o_cmd{'project.io'} =  $$cmd_info{'project.io'};
  $$o_cmd{'project.output'} = $$cmd_info{'project.output'};
  $$o_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
  $$o_cmd{'cmd-flags'} = '@' . $opts_path;
  $$o_cmd{'output'} = $$cmd_info{'output'};
  $$o_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo = 0;
  if ($ENV{'DK_ECHO_COMPILE_CMD'}) {
    $should_echo = 1;
  }
  if (0) {
    $$o_cmd{'cmd-flags'} .= " -MMD";
    return &outfile_from_infiles($o_cmd, $should_echo);
    $$o_cmd{'cmd-flags'} =~ s/ -MMD//g;
  }
  return &outfile_from_infiles($o_cmd, $should_echo);
}
sub rt_o_from_json {
  my ($cmd_info, $other, $is_exe) = @_;
  die if ! defined $$cmd_info{'reps'} || 0 == @{$$cmd_info{'reps'}};
  my $rt_json_path = &rt_json_path($cmd_info);
  my $rt_cc_path =   &rt_cc_path($cmd_info);
  &check_path($rt_json_path);
  my $rt_o_path = &o_path_from_cc_path($rt_cc_path);
  if (!$$cmd_info{'opts'}{'silent'}) {
    print $rt_o_path . $nl;
  }
  my $rt_hh_path = $rt_cc_path =~ s/\.$cc_ext$/\.$hh_ext/r;

  my $project_io = &scalar_from_file($$cmd_info{'project.io'});
  $$project_io{'all'}{$rt_json_path}{$rt_hh_path} = 1;
  $$project_io{'all'}{$rt_json_path}{$rt_cc_path} = 1;
  $$project_io{'all'}{$rt_hh_path}{$rt_o_path} = 1;
  $$project_io{'all'}{$rt_cc_path}{$rt_o_path} = 1;
  &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);

  &make_dir($rt_cc_path);
  my ($path, $file_basename, $file) = ($rt_cc_path, $rt_cc_path, undef);
  $path =~ s|/[^/]*$||;
  $file_basename =~ s|^[^/]*/||;       # strip off leading $objdir/
  $file_basename =~ s|-rt\.$cc_ext$||; # strip off trailing -rt.cc
  my $global_rep = &init_global_rep($$cmd_info{'reps'}); # within rt_o_from_json
  $file = &scalar_from_file($rt_json_path);
  die if $$file{'other'};
  $$file{'other'} = $other;
  $file = &kw_args_translate($file);
  $$file{'should-generate-make'} = 1;

  &rt::add_extra_symbols($file);
  &rt::add_extra_klass_decls($file);
  &rt::add_extra_keywords($file);

  &nrt::add_extra_symbols($file);
  &nrt::add_extra_klass_decls($file);
  &nrt::add_extra_keywords($file);
  &nrt::add_extra_generics($file);

  my $project_rep;
  &dakota::generate::generate_rt_decl($rt_cc_path, $file, $project_rep = undef, $is_exe);
  &dakota::generate::generate_rt_defn($rt_cc_path, $file, $project_rep = undef, $is_exe);

  my $o_info = {'opts' => {}, 'inputs' => [ $rt_cc_path ], 'output' => $rt_o_path };
  $$o_info{'project.io'} =  $$cmd_info{'project.io'};
  if ($$cmd_info{'opts'}{'precompile'}) {
    $$o_info{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
  }
  if ($$cmd_info{'opts'}{'compiler'}) {
    $$o_info{'opts'}{'compiler'} = $$cmd_info{'opts'}{'compiler'};
  }
  if ($$cmd_info{'opts'}{'compiler-flags'}) {
    $$o_info{'opts'}{'compiler-flags'} = $$cmd_info{'opts'}{'compiler-flags'};
  }
  if (!$ENV{'DKT_PRECOMPILE'}) {
    &o_from_cc($o_info, &compile_opts_path(), $cxx_compile_flags);
    &add_first($$cmd_info{'inputs'}, $rt_o_path);
  }
}
sub gcc_libraries_str {
  my ($library_names) = @_;
  my $gcc_libraries = [];
  foreach my $library_name (@$library_names) {
    push @$gcc_libraries, &gcc_library_from_library_name($library_name);
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
  my $ldflags =       &dakota::util::var($gbl_compiler, 'LDFLAGS', '');
  my $extra_ldflags = &dakota::util::var($gbl_compiler, 'EXTRA_LDFLAGS', '');
  my $opts = '';
  $opts .= $mode_flags . $nl if $mode_flags;
  $opts .=
    $ldflags . $nl .
    $extra_ldflags . $nl .
    '@' . &common_opts_path() . $nl;
  $opts =~ s/^\s+//gs;
  $opts =~ s/\s+$//gs;
  $opts =~ s/\s+/\n/g;
  open(my $fh, '>', $opts_path);
  print $fh $opts . $nl;
  close($fh);
  $$cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
  $$cmd{'cmd-flags'} = '@' . $opts_path;
  $$cmd{'output'} = $$cmd_info{'output'};
  $$cmd{'project.output'} = $$cmd_info{'project.output'};
  $$cmd{'inputs'} =     $$cmd_info{'inputs'};
  $$cmd{'inputs-tbl'} = $$cmd_info{'inputs-tbl'};
  &library_names_add_first($cmd);
  my $should_echo = 0;
  if ($ENV{'DK_ECHO_LINK_CMD'} || $ENV{'DK_ECHO_LINK_EXE_CMD'}) {
    $should_echo = 1;
  }
  my $result = &outfile_from_infiles($cmd, $should_echo);
  if ($result) {
    &project_io_add($cmd_info, $$cmd{'inputs'}, $$cmd{'output'});
  }
  return $result;
}
sub dir_part {
  my ($path) = @_;
  my $parts = [split /\//, $path];
  &dakota::util::remove_last($parts);
  my $dir = join '/', @$parts;
  return $dir;
}
sub make_dir {
  my ($path) = @_;
  my $dir_part = &dir_part($path);
  if ("" ne $dir_part) {
    if (! -e $dir_part) {
      my $cmd = { 'cmd' => 'mkdir', 'cmd-flags' => '-p', 'inputs' => [ $dir_part ] };
      #my $cmd_str = &str_from_cmd_info($cmd);
      #print "  $cmd_str\n";
      my $should_echo;
      &exec_cmd($cmd, $should_echo = 0);
    }
  }
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
  if ($outfile =~ m|^$objdir/$objdir/|) { die "found double objdir/objdir: $outfile"; } # likely a double $objdir prepend
  my $infiles;
  if (-e $outfile) {
    my $file_db = {};
    $infiles = [];
    foreach my $infile (@{$$cmd_info{'inputs'}}) {
      if (&is_out_of_date($infile, $outfile, $file_db)) {
        push @$infiles, $infile;
      }
    }
  } else {
    $infiles = $$cmd_info{'inputs'};
  }
  my $num_out_of_date_infiles = @$infiles;
  if (0 != $num_out_of_date_infiles) {
    &make_dir($$cmd_info{'output'});
    if ($show_outfile_info) {
      print "MK $$cmd_info{'output'}\n";
    }
    my $output = $$cmd_info{'output'};

    if (!&is_rep_path($output) &&
        !&is_ctlg_path($output)) {
      #$should_echo = 0;
      if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
        $output = $ENV{'DKT_DIR'} . '/' . $output
      }
      #print "    creating $output # output" . &pann(__FILE__, __LINE__) . $nl;
    }
    if ('&loop_merged_rep_from_inputs' eq $$cmd_info{'cmd'}) {
      $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
      delete $$cmd_info{'output'};
      delete $$cmd_info{'cmd'};
      delete $$cmd_info{'cmd-flags'};
      &loop_merged_rep_from_inputs($cmd_info, $global_should_echo || $should_echo);
    } elsif ('&loop_cc_from_dk' eq $$cmd_info{'cmd'}) {
      $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
      delete $$cmd_info{'output'};
      delete $$cmd_info{'cmd'};
      delete $$cmd_info{'cmd-flags'};
      &loop_cc_from_dk($cmd_info, $global_should_echo || $should_echo);
    } else {
      &exec_cmd($cmd_info, $should_echo);
    }

    if (0) {
      &project_io_add($cmd_info, $infiles, $output);
    } else {
      my $project_io = &scalar_from_file($$cmd_info{'project.io'});
      foreach my $input (@$infiles) {
        $input =~ s=^--library-directory\s+(.+)\s+-l(.+)$=$1/lib$2.$so_ext=;
        $input = &canon_path($input);
        $$project_io{'all'}{$input}{$output} = 1;
      }
      &scalar_to_file($$cmd_info{'project.io'}, $project_io);
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
  } elsif ($gbl_prefix) {
    $$ctlg_cmd{'cmd'} = "$gbl_prefix/bin/dakota-catalog";
  } else {
    die "should not call just any dakota-catalog"; # should we call just any dakota-catalog?
    $$ctlg_cmd{'cmd'} = 'dakota-catalog';
  }
  if ($$cmd_info{'opts'}{'silent'} && !$$cmd_info{'opts'}{'echo-inputs'}) {
    $$ctlg_cmd{'cmd'} .= ' --silent';
  }
  $$ctlg_cmd{'output'} = $$cmd_info{'output'};
  $$ctlg_cmd{'project.output'} = $$cmd_info{'project.output'};
  $$ctlg_cmd{'output-directory'} = $$cmd_info{'output-directory'};
  if ($ENV{'DKT_PRECOMPILE'}) {
    my $precompile_inputs = [];
    foreach my $input (@{$$cmd_info{'inputs'}}) {
      if (-e $input) {
        &dakota::util::add_last($precompile_inputs, $input);
      } else {
        print STDERR "warning: $input does not exist.\n";
        my $json_path;
        if (&is_so_path($input)) {
          my $ctlg_path = &ctlg_path_from_so_path($input);
          $json_path = &json_path_from_ctlg_path($ctlg_path);

          my $project_io = &scalar_from_file($$cmd_info{'project.io'});
          $input = &canon_path($input);
          $$project_io{'all'}{$input}{$ctlg_path} = 1;
          $$project_io{'all'}{$ctlg_path}{$json_path} = 1;
          &scalar_to_file($$cmd_info{'project.io'}, $project_io, 1);

        } elsif (&is_dk_src_path($input)) {
          $json_path = &json_path_from_dk_path($input);
          &check_path($json_path);
        } else {
          #print "skipping $input, line=" . __LINE__ . $nl;
        }
        if (-e $json_path) {
         #my $ctlg_path = $json_path . '.' . 'ctlg';
          my $ctlg_path = $json_path =~ s/\.json$/\.ctlg/r;
          print STDERR "warning: consider using $json_path to create $ctlg_path.\n";
        }
        #&dakota::util::add_last($precompile_inputs, $input);
        #&dakota::util::add_last($precompile_inputs, $json_path);
      }
    }
    $$ctlg_cmd{'inputs'} = $precompile_inputs;
  } else {
    $$ctlg_cmd{'inputs'} = $$cmd_info{'inputs'};
  }
  #print &Dumper($cmd_info);
  my $should_echo;
  return &outfile_from_infiles($ctlg_cmd, $should_echo = 0);
}
sub ordered_set_add {
  my ($ordered_set, $element, $file, $line) = @_;
  foreach my $member (@$ordered_set) {
    if ($element eq $member) {
      #printf STDERR "%s:%i: warning: element \"$element\" already present\n", $file, $line;
      return;
    }
  }
  &dakota::util::add_last($ordered_set, $element);
}
sub ordered_set_add_first {
  my ($ordered_set, $element, $file, $line) = @_;
  foreach my $member (@$ordered_set) {
    if ($element eq $member) {
      #printf STDERR "%s:%i: warning: element \"$element\" already present\n", $file, $line;
      return;
    }
  }
  &dakota::util::add_first($ordered_set, $element);
}
sub start {
  my ($argv) = @_;
  # just in case ...
}
unless (caller) {
  &start(\@ARGV);
}
1;
