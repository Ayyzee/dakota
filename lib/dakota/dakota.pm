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
                 is_target_inputs_ast_path
                 is_target_hdr_path
                 is_target_src_path
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

# output=foo.dk.ast, inputs=[foo.dk]
# or
# output=xxx.ctlg.ast, inputs=[xxx.ctlg]
# or
# output=srcs.ast, inputs=[foo.dk.ast, bar.dk.ast, ...]
sub loop_merged_ast_from_inputs {
  my ($cmd_info, $should_echo) = @_; 
  die if ! $$cmd_info{'opts'}{'output'};
  if ($should_echo) {
    print STDERR '  &loop_merged_ast_from_inputs --output ' .
      $$cmd_info{'opts'}{'output'} . ' ' . join(' ', @{$$cmd_info{'inputs'}}) . $nl;
  }
  &init_ast_from_inputs_vars($cmd_info);
  my $ast_paths = [];
  if ($$cmd_info{'ast-paths'}) {
    $ast_paths = $$cmd_info{'ast-paths'};
  }
  my ($ast_path, $ast);
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_dk_src_path($input)) {
      ($ast_path, $ast) = &ast_from_dk($input);
    } elsif (&is_ast_path($input)) {
      $ast_path = $input;
      $ast = &scalar_from_file($ast_path);
    } else {
      die __FILE__, ":", __LINE__, ": ERROR\n";
    }
    &add_last($ast_paths, $ast_path);
  }
  if ($$cmd_info{'opts'}{'output'}) {
    if ($$cmd_info{'opts'}{'output'} eq &target_srcs_ast_path()) { # z/srcs.ast ($target_srcs_ast)
      my $should_translate;
      &ast_merge(&target_srcs_ast_path(), $ast_paths, $should_translate = 0);
    } elsif (1 == @{$$cmd_info{'inputs'}}) {
    } else {
      die;
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
  return if ! exists $$ast{'modules'};
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
  my $current_intmd_dir = &current_intmd_dir();
  my $result = &target_src_path() =~ s=^$current_intmd_dir/\+/(.+?)$cc_ext$=$1-klass-func-decls.inc=r;
  return $result;
}
sub target_klass_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $current_intmd_dir = &current_intmd_dir();
  my $result = &target_src_path() =~ s=^$current_intmd_dir/\+/(.+?)$cc_ext$=$1-klass-func-defns.inc=r;
  return $result;
}
sub target_generic_func_decls_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $current_intmd_dir = &current_intmd_dir();
  my $result = &target_src_path() =~ s=^$current_intmd_dir/\+/(.+?)$cc_ext$=$1-generic-func-decls.inc=r;
  return $result;
}
sub target_generic_func_defns_path {
  my ($cmd_info) = @_;
  $cmd_info = &default_cmd_info() if ! $cmd_info;
  my $current_intmd_dir = &current_intmd_dir();
  my $result = &target_src_path() =~ s=^$current_intmd_dir/\+/(.+?)$cc_ext$=$1-generic-func-defns.inc=r;
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
  my $ast_paths = [];
  if ($$cmd_info{'ast-paths'}) {
    $ast_paths = $$cmd_info{'ast-paths'};
  }
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if (&is_ast_path($input)) {
      &add_last($ast_paths, $input);
    } else {
      &add_last($inputs, $input);
    }
  }
  $$cmd_info{'ast-paths'} = $ast_paths;
  $$cmd_info{'inputs'} = $inputs;

  my $num_inputs = @{$$cmd_info{'inputs'}};
  if (0 == $num_inputs) {
    die "$0: error: arguments are requried\n";
  }
  my $target_inputs_ast = &target_inputs_ast(); # within cc_from_dk_core2
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    my $ast_path;
    if (&is_so_path($input)) {
      my $ctlg_path = &ctlg_path_from_so_path($input);
      $ast_path = &ast_path_from_ctlg_path($ctlg_path);
    } elsif (&is_dk_src_path($input)) {
      $ast_path = &ast_path_from_dk_path($input);
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
    my $inc_path = &inc_path_from_dk_path($input);
    my $h_path = $cc_path =~ s/$cc_ext$/$h_ext/r;
    $input = &canon_path($input);
    &empty_klass_defns();
    &dk_generate_cc($input, $inc_path, $target_inputs_ast);
    &src::add_extra_symbols($file_ast);
    &src::add_extra_klass_decls($file_ast);
    &src::add_extra_keywords($file_ast);
    &src::add_extra_generics($file_ast);
    my $rel_target_hdr_path = &rel_target_hdr_path();

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
sub ordered_cc_paths {
  my ($seq) = @_;
  my $ordered_cc_paths = [];
  foreach my $cc_path (@$seq) {
    if (&is_cc_path($cc_path)) {
      &add_last($ordered_cc_paths, $cc_path);
    }
  }
  return $ordered_cc_paths;
}
# should only be called after all the target ast paths have been created
sub ast_paths_from_parts {
  my ($paths, $force) = @_;
  my $ast_paths = [ &target_srcs_ast_path() ];
  foreach my $path (@$paths) {
    if (&is_so_path($path)) {
      my $ctlg_path = &ctlg_path_from_so_path($path);
      if (($force && $force != 0) || -s $ctlg_path) {
        &add_last($ast_paths, &ast_path_from_ctlg_path($ctlg_path));
      }
    }
  }
  return $ast_paths;
}
sub ast_paths_from_inputs {
  my ($inputs) = @_;
  my $srcs_ast;
  my $ast_paths = [];
  foreach my $input (@$inputs) {
    if ($input =~ /\.ctlg\.ast$/) {
      &add_last($ast_paths, $input);
    } elsif ($input =~ /srcs\.ast$/) {
      $srcs_ast = $input;
    }
  }
  die if ! $srcs_ast;
  &add_last($ast_paths, $srcs_ast);
  return $ast_paths;
}
sub is_target_hdr_path {
  my ($path) = @_;
  return $path eq &target_hdr_path();
}
sub is_target_src_path {
  my ($path) = @_;
  return $path eq &target_src_path();
}
sub is_target_inputs_ast_path {
  my ($path) = @_;
  return $path eq &target_inputs_ast_path();
}
sub cmd_line_action_parse {
  my ($input, $output) = @_;
  my ($ast_path, $ast) = &ast_from_dk($input, $output);
}
sub cmd_line_action_merge {
  my ($inputs, $output) = @_;
  my $output_base = &basename($output);
  die if $output_base ne 'srcs.ast' && $output_base ne 'inputs.ast';
  if ($output_base eq 'inputs.ast') {
    my $ast_paths = &ast_paths_from_inputs($inputs);
  }
  my $should_translate = ($output_base eq 'inputs.ast');
  &ast_merge($output, $inputs, $should_translate);
  if ($output_base eq 'srcs.ast') {
    &add_visibility_file($output);
  }
}
sub make_gen_target_cmd_info {
  my ($inputs, $output, $action) = @_;
  my $cmd_info = { 'opts' => { 'action' => $action } };
  $$cmd_info{'inputs'} = $inputs;
  $$cmd_info{'output'} = $output;
  $$cmd_info{'parts'} = &parts();
  $$cmd_info{'ast-paths'} = &ast_paths_from_parts($$cmd_info{'parts'});
  &set_root_cmd($cmd_info);
}
sub cmd_line_action_gen_target_hdr {
  my ($inputs, $output) = @_;
  my $cmd_info = &make_gen_target_cmd_info($inputs, $output, 'gen-target-hdr');
  &gen_target_hdr($cmd_info);
}
sub cmd_line_action_gen_target_src {
  my ($inputs, $output) = @_;
  my $cmd_info = &make_gen_target_cmd_info($inputs, $output, 'gen-target-src');
  &gen_target_src($cmd_info);
}
sub num_cpus {
  my $result = `getconf _NPROCESSORS_ONLN`;
  chomp $result;
  return $result;
}
use Time::HiRes;
sub start_cmd {
  my ($cmd_info) = @_;
  my $ordered_cc_paths = [];
  $$cmd_info{'output'} = $$cmd_info{'opts'}{'output'} if $$cmd_info{'opts'}{'output'};
  if ($$cmd_info{'opts'}{'action'}) {
    my $t0 = Time::HiRes::time();
    if (0) {
    } elsif ($$cmd_info{'opts'}{'action'} eq 'parse') {
      die if scalar @{$$cmd_info{'inputs'}} != 1;
      &cmd_line_action_parse($$cmd_info{'inputs'}[0], $$cmd_info{'opts'}{'output'});
    } elsif ($$cmd_info{'opts'}{'action'} eq 'merge') {
      die if scalar @{$$cmd_info{'inputs'}} == 0;
      &cmd_line_action_merge($$cmd_info{'inputs'}, $$cmd_info{'opts'}{'output'});
    } elsif ($$cmd_info{'opts'}{'action'} eq 'gen-target-hdr') {
      my $target_hdr_path = &target_hdr_path();
      if ($$cmd_info{'opts'}{'path-only'}) {
        print $target_hdr_path . $nl;
        exit 0;
      }
      $$cmd_info{'output'} = $target_hdr_path if ! $$cmd_info{'output'}; # set the default value
      &cmd_line_action_gen_target_hdr($$cmd_info{'inputs'}, $$cmd_info{'output'});
    } elsif ($$cmd_info{'opts'}{'action'} eq 'gen-target-src') {
      my $target_src_path = &target_src_path();
      if ($$cmd_info{'opts'}{'path-only'}) {
        print $target_src_path . $nl;
        exit 0;
      }
      $$cmd_info{'output'} = $target_src_path if ! $$cmd_info{'output'}; # set the default value
      &cmd_line_action_gen_target_src($$cmd_info{'inputs'}, $$cmd_info{'output'});
    } else { die; }
    my $t1 = Time::HiRes::time();
    if (! $ENV{'silent'} && $$cmd_info{'opts'}{'action'} ne 'parse') {
      my $pad = '';
      my $path = $$cmd_info{'output'};
      die if ! $path;
      if ($$cmd_info{'opts'}{'action'} eq 'merge') {
        $pad = ' ' x 9;
      }
      if ($ENV{'silent'}) {
        my $dir = &dirname(&current_intmd_dir());
        $path =~ s#^$dir/##;
        my $str = sprintf("elapsed: %4.1fs: %s: %s%s\n", $t1 - $t0, $$cmd_info{'opts'}{'action'}, $pad, $path);
        print STDERR $str;
      }
    }
    return $ordered_cc_paths = [];
  } else {
    # replace dk-paths with cc-paths
    $cmd_info = &loop_cc_from_dk($cmd_info);
    $ordered_cc_paths = &ordered_cc_paths($$cmd_info{'inputs'});
  }
  return $ordered_cc_paths;
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
  my $ast_path;
  if (-s $ctlg_path) { # no ast path is created when ctlg path is a zero length file
    $ast_path = &ast_path_from_ctlg_path($ctlg_path);
    &ordered_set_add($$cmd_info{'ast-paths'}, $ast_path, __FILE__, __LINE__);
    my $ast_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$ast_cmd{'output'} = $ast_path;
    $$ast_cmd{'inputs'} = [ $ctlg_path ];
    $$ast_cmd{'io'} =  $$cmd_info{'io'};
    &ast_from_inputs($ast_cmd);
    if (!$should_write_ctlg_files) {
      #unlink $ctlg_path;
    }
  }
  return ($ast_path, undef);
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
  my $num_out_of_date_infiles = &outfile_from_infiles($ast_cmd, $should_echo = 0);
  if ($num_out_of_date_infiles) {
    foreach my $input (@{$$ast_cmd{'inputs'}}) {
      if (&is_so_path($input)) {
        my $ctlg_path = &ctlg_path_from_so_path($input);
        my $ast_path = &ast_path_from_ctlg_path($ctlg_path);
      } elsif (&is_dk_path($input)) {
        my $ast_path = &ast_path_from_dk_path($input);
      } elsif (&is_ctlg_path($input)) {
        my $ast_path = &ast_path_from_ctlg_path($input);
      } else {
        #print "skipping $input, line=" . __LINE__ . $nl;
      }
    }
  }
}
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
  my $target_srcs_ast_path = &target_srcs_ast_path();
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
      my $ast_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$ast_cmd{'inputs'} = [ $input ];
      $$ast_cmd{'output'} = $ast_path;
      $$ast_cmd{'io'} =  $$cmd_info{'io'};
      &ast_from_inputs($ast_cmd);
      if (-s $ast_path) { # only add ast paths that exist and are non-zero length
        &ordered_set_add($$cmd_info{'ast-paths'}, $ast_path, __FILE__, __LINE__);
      }
    }
    my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$cc_cmd{'inputs'} = [ $input ];
    $$cc_cmd{'output'} = $src_path;
    $$cc_cmd{'ast-paths'} = $$cmd_info{'ast-paths'};
    $$cc_cmd{'io'} =  $$cmd_info{'io'};
    $num_out_of_date_infiles = &cc_from_dk_core1($cc_cmd);
    $outfile = $$cc_cmd{'output'};
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
  $$cc_cmd{'ast-paths'} = $$cmd_info{'ast-paths'};
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
  die if ! defined $$cmd_info{'output'};
  die if ! defined $$cmd_info{'ast-paths'} || 0 == @{$$cmd_info{'ast-paths'}};
  die if ! defined $$cmd_info{'opts'}{'action'};
  my $target_srcs_ast_path = &target_srcs_ast_path();

  if ($is_defn) {
    if ($$cmd_info{'opts'}{'action'} eq 'gen-target-hdr') {
      return if !&is_out_of_date($target_srcs_ast_path, $$cmd_info{'output'});
    }
  } elsif ($$cmd_info{'opts'}{'action'} eq 'gen-target-src') {
    return if !&is_out_of_date($target_srcs_ast_path, $$cmd_info{'output'});
  }
  &make_dirname($$cmd_info{'output'}, $global_should_echo);
  my $target_srcs_ast;
  $target_srcs_ast = &scalar_from_file($target_srcs_ast_path);
  $target_srcs_ast = &kw_args_translate($target_srcs_ast);

  &target::add_extra_symbols($target_srcs_ast);
  &target::add_extra_klass_decls($target_srcs_ast);
  &target::add_extra_keywords($target_srcs_ast);

  &src::add_extra_symbols($target_srcs_ast);
  &src::add_extra_klass_decls($target_srcs_ast);
  &src::add_extra_keywords($target_srcs_ast);
  &src::add_extra_generics($target_srcs_ast);

  my $target_inputs_ast = &target_inputs_ast(); # within target_src_from_ast
  if ($is_defn) {
    &generate_target_defn($$cmd_info{'output'}, $target_srcs_ast, $target_inputs_ast);
  } else {
    &generate_target_decl($$cmd_info{'output'}, $target_srcs_ast, $target_inputs_ast);
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
  &make_dirname($outfile, $should_echo);
  my $file_db = {};
  my $infiles = &out_of_date($$cmd_info{'inputs'}, $outfile, $file_db);
  my $num_out_of_date_infiles = scalar @$infiles;
  if (0 != $num_out_of_date_infiles) {
    #print STDERR "outfile=$outfile, infiles=[ " . join(' ', @$infiles) . ' ]' . $nl;
    &make_dirname($$cmd_info{'output'}, $should_echo);
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
