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

package dakota::parse;

use strict;
use warnings;
use sort 'stable';

my $gbl_compiler;
my $gbl_used;
my $builddir;
my $hh_ext;
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
sub hh_path_from_cc_path {
  my ($cc_path) = @_;
  my $hh_path = $cc_path =~ s/\.$cc_ext/\.$hh_ext/r;
  return $hh_path;
}
# related to generate.pm:pre_output_path_from_any_path()
sub dk_path_from_cc_path { # reverse dependency
  my ($cc_path) = @_;
  my $dk_path = $cc_path =~ s/\.$cc_ext$/.dk/r;
  return $dk_path;
}
sub cc_path_from_dk_path {
  my ($path) = @_;
  return &out_path_from_in_path('cc_path_from_dk_path', $path);
}
sub hh_path_from_src_path {
  my ($src_path) = @_;
  my $hh_path = $src_path =~ s/\.(dk|$cc_ext)$/.$hh_ext/r;
  return $hh_path;
}
sub ast_path_from_o_path {
  my ($in_path) = @_;
  my $out_path = $in_path =~ s/(\.($cc_ext|dk))?\.$o_ext$/.dk.ast/r; # hackhack
  return $out_path;
}
my $patterns = {
  'cc_path_from_dk_path' => '$(builddir)/%.$(cc_ext) : %.dk',

  'o_path_from_dk_path' =>  '$(builddir)/%.$(cc_ext).$(o_ext) : %.dk',
  'o_path_from_cc_path' =>  '%.$(cc_ext).$(o_ext) : %.$(cc_ext)',

  'ast_path_from_dk_path' =>   '$(builddir)/%.ast      : %.dk',
  'ast_path_from_ctlg_path' => '%.ctlg.ast : %.ctlg',

  'ctlg_path_from_so_path' =>   '$(builddir)/%.ctlg : %.$(so_ext)',
};
#print STDERR &Dumper($expanded_patterns);

BEGIN {
  my $prefix = &dk_prefix($0);
  unshift @INC, "$prefix/lib";
  use dakota::sst;
  use dakota::util;
  $gbl_compiler = do "$prefix/lib/dakota/compiler/command-line.json"
    or die "do $prefix/lib/dakota/compiler/command-line.json failed: $!\n";
  my $platform = do "$prefix/lib/dakota/platform.json"
    or die "do $prefix/lib/dakota/platform.json failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $gbl_used = do "$prefix/lib/dakota/used.json"
    or die "do $prefix/lib/dakota/used.json failed: $!\n";
  $hh_ext = &var($gbl_compiler, 'hh_ext', undef);
  $cc_ext = &var($gbl_compiler, 'cc_ext', undef);
  $o_ext =  &var($gbl_compiler, 'o_ext', undef);
  $so_ext = &var($gbl_compiler, 'so_ext', 'so'); # default dynamic shared object/library extension
};
#use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Cwd;
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
                 add_generic
                 add_keyword
                 add_klass_decl
                 add_str
                 add_symbol
                 add_trait_decl
                 ast_from_dk_path
                 cc_path_from_dk_path
                 ctlg_path_from_so_path
                 dk_path_from_cc_path
                 inc_path_from_dk_path
                 init_ast_from_inputs_vars
                 hh_path_from_cc_path
                 hh_path_from_src_path
                 target_inputs_ast
                 kw_args_translate
                 o_path_from_dk_path
                 o_path_from_cc_path
                 ast_path_from_dk_path
                 ast_path_from_ctlg_path
                 ast_path_from_o_path
                 ast_merge
                 str_from_cmd_info
              );
my $colon = ':'; # key/element delim only
my $kw_arg_placeholders = &kw_arg_placeholders();
my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &ident_regex();
my $h =  &header_file_regex();

$ENV{'DKT-DEBUG'} = 0;

sub kw_args_translate {
  my ($ast) = @_;
  my $keys = [sort keys %{$$ast{'generics'}}];
  foreach my $generic (@$keys) {
    my $va_generic = $generic;

    if ($generic =~ s/^va:://) {
      delete $$ast{'generics'}{$va_generic};
      $$ast{'generics'}{$generic} = undef;
    }
  }

  my $constructs = [ 'klasses', 'traits' ];
  foreach my $construct (@$constructs) {
    my ($name, $scope);
    if ($$ast{$construct}) {
      while (($name, $scope) = each %{$$ast{$construct}}) {
        foreach my $method (values %{$$scope{'methods'}}, values %{$$scope{'slots-methods'}}) {
          if (&has_va_prefix($method)) {
            &remove_name_va_scope($method);
          }

          if ($$method{'kw-arg-names'}) {
            my $kw_arg_types = [];
            my $kw_args_name;        # not used
            foreach $kw_args_name (@{$$method{'kw-arg-names'}}) {
              my $kw_args_type =
                &remove_last($$method{'param-types'});
              &add_last($kw_arg_types, $kw_args_type);
            }
            &update_to_kw_args($method);
            my $kw_arg_defaults = [];
            my $kw_args_default;
            if (exists  $$method{'kw-arg-defaults'} &&
                defined $$method{'kw-arg-defaults'}) {
              while ($kw_args_default =
                       &remove_last($$method{'kw-arg-defaults'})) {
                my $val = join(' ', @$kw_args_default);
                $val = &remove_extra_whitespace($val);
                &add_last($kw_arg_defaults, $val);
              }
            } # if
            my $no_default = @$kw_arg_types - @$kw_arg_defaults;
            while ($no_default) {
              $no_default--;
              &add_last($kw_arg_defaults, undef);
            }
            my $kw_args_type;
            while (scalar @$kw_arg_types) {
              my $kw_arg = {
                type =>    &remove_last($kw_arg_types),
                default => &remove_last($kw_arg_defaults),
                name =>    &remove_first($$method{'kw-arg-names'}) };

              &add_last($$method{'kw-args'}, $kw_arg);
            }
            delete $$method{'kw-arg-names'};
            delete $$method{'kw-arg-defaults'};
          } else {
            if (&is_kw_args_method($method)) {
              if (!&is_va($method)) {
                &update_to_kw_args($method);
              }
            }
          }
        }
      }
    }
  }
  return $ast;
}
sub update_to_kw_args {
  my ($method) = @_;
  die if &is_va($method);
  die if $$method{'kw-args'};
  &add_last($$method{'param-types'}, [ 'va-list-t' ]);
  $$method{'kw-args'} = [];
}
sub tbl_add_info {
  my ($root_tbl, $tbl) = @_;
  while (my ($key, $element) = each %$tbl) {
    if (!exists $$root_tbl{$key}) {
      $$root_tbl{$key} = $$tbl{$key};
    } elsif (exists  $$root_tbl{$key} &&
            !defined $$root_tbl{$key} &&
             defined $$tbl{$key}) {
      $$root_tbl{$key} = $$tbl{$key};
    }
  }
}
sub is_tbl {
  my ($v) = @_;
  my $result = 0;
  if ('HASH' eq ref($v)) {
    $result = 1;
  }
  return $result;
}
sub _ast_merge {
  my ($root_ast, $ast) = @_;
  foreach my $name1 (sort keys %$ast) {
    if (&is_tbl($$ast{$name1})) {
      foreach my $name2 (sort keys %{$$ast{$name1}}) {
        if (!$$ast{$name1}{$name2}) {
          if (!exists $$root_ast{$name1}{$name2}) {
            $$root_ast{$name1}{$name2} = undef;
          }
        } else {
          if (!$$root_ast{$name1}{$name2}) {
            $$root_ast{$name1}{$name2} = &deep_copy($$ast{$name1}{$name2});
          } else {
            if (&is_tbl($$ast{$name1}{$name2})) {
              foreach my $name3 (sort keys %{$$ast{$name1}{$name2}}) {
                if (&is_tbl($$ast{$name1}{$name2}{$name3})) {
                  &tbl_add_info($$root_ast{$name1}{$name2}{$name3},
                                $$ast{$name1}{$name2}{$name3});
                }
              }
            } else {
              $$root_ast{$name1}{$name2} = $$ast{$name1}{$name2};
            }
          }
        }
      }
    }
  }
}
sub ast_merge {
  my ($outpath, $argv, $should_translate) = @_;
  my $ast = {};
  my $files = &out_of_date($argv, $outpath);
  if (-e $outpath) {
    $ast = &scalar_from_file($outpath);
    if (0 == scalar @$files) {
      return $ast;
    }
  }
  #print STDERR "ast_merge(): $outpath: " . &Dumper($files);
  foreach my $file (@$files) {
    my $file_ast = &scalar_from_file($file);
    &_ast_merge($ast, $file_ast);
  }
  if ($should_translate) {
    $ast = &kw_args_translate($ast);
  }
  &scalar_to_file($outpath, $ast);
  return $ast;
}

my $gbl_sst = undef;
my $gbl_sst_cursor = undef;
my $gbl_user_data = &dakota::sst::lang_user_data();

my $gbl_root_ast = {};
my $gbl_current_ast_scope = $gbl_root_ast;
my $gbl_current_module = undef;
my $gbl_filename = undef;
sub init_ast_from_inputs_vars {
  my ($cmd_info) = @_;
  $gbl_root_ast = {};
  $$gbl_root_ast{'keywords'} = {};
  $$gbl_root_ast{'symbols'} =  {};

  $gbl_current_ast_scope = $gbl_root_ast;
  $gbl_filename = undef;
}
sub str_from_cmd_info {
  my ($cmd_info) = @_;

  my $str = '';
  if (defined $$cmd_info{'cmd'}) {
    $str .= $$cmd_info{'cmd'};
  } else {
    $str .= '<>';
  }
  if ($$cmd_info{'cmd-flags'}) {
    $str .= " $$cmd_info{'cmd-flags'}";
  }
  if ($$cmd_info{'output'}) {
    $str .= " --output=" . $$cmd_info{'output'};
  }
  if ($$cmd_info{'output-directory'}) {
    $str .= " --output-directory=" . $$cmd_info{'output-directory'};
  }
  foreach my $infile (@{$$cmd_info{'asts'}}) {
    $str .= " $infile";
  }
  foreach my $infile (@{$$cmd_info{'inputs'}}) {
    if ($$cmd_info{'inputs-tbl'}{$infile}) {
      $str .= " $$cmd_info{'inputs-tbl'}{$infile}";
    } else {
      $str .= " $infile";
    }
  }
  $str =~ s|(\s)\s+|$1|g;
  return $str;
}
sub inc_path_from_dk_path {
  my ($path) = @_;
  my ($dir, $name) = &split_path($path);
  $name =~ s/\.dk$/.inc/;
  my $inc_path = &builddir() . '/' . $dir . '/'. $name;
  return &canon_path($inc_path);
}
sub o_path_from_dk_path {
  my ($path) = @_;
  return &out_path_from_in_path('o_path_from_dk_path', $path);
}
sub o_path_from_cc_path {
  my ($path) = @_;
  return &out_path_from_in_path('o_path_from_cc_path', $path);
}
sub ctlg_path_from_so_path {
  my ($in_path) = @_;
  $in_path =~ s/\.$so_ext((\.\d+)+)$/.$so_ext/;
  my $vers = $1;
  my $out_path = &out_path_from_in_path('ctlg_path_from_so_path', $in_path);
  if (defined $vers) {
    $out_path =~ s/\.ctlg$/.ctlg$vers/;
  }
  return $out_path;
}
sub ast_path_from_ctlg_path {
  my ($in_path) = @_;
  my $out_path = &out_path_from_in_path('ast_path_from_ctlg_path', $in_path);
  return $out_path;
}
sub ast_path_from_dk_path {
  my ($in_path) = @_;
  if (&use_abs_path()) {
    $in_path = &Cwd::abs_path($in_path);
  }
  my $out_path = &out_path_from_in_path('ast_path_from_dk_path', $in_path);
  return $out_path;
}
sub var_perl_from_make { # convert variable syntax to perl from make
  my ($str) = @_;
  my $result = $str;
  $result =~ s|\$\((\w+)\)|\$$1|g;
  $result =~ s|\$\{(\w+)\}|\$$1|g;
  return $result;
}
sub expand {
  my ($str) = @_;
  $builddir if 0;
  $cc_ext if 0;
  $o_ext  if 0;
  $so_ext if 0;
  $str =~ s/(\$\w+)/$1/eeg;
  return $str;
}
### $s if 0;
sub expand_tbl_values {
  my ($tbl_in, $tbl_out) = @_;
  if (!$tbl_out) { $tbl_out = {}; }
  my ($key, $val); while (($key, $val) = each (%$tbl_in)) {
    $val =~ s|\s*:\s*|:|; # just hygenic
    $val = &expand(&var_perl_from_make($val));
    $$tbl_out{$key} = $val;
  }
  return $tbl_out;
}
sub out_path_from_in_path {
  my ($pattern_name, $path_in) = @_;
  $path_in = &canon_path($path_in);
  $builddir = &builddir();
  my $expanded_patterns = &expand_tbl_values($patterns);
  my $pattern = $$expanded_patterns{$pattern_name} =~ s|\s*:\s*|:|r; # just hygenic
  my ($pattern_replacement, $pattern_template) = split(/\s*:\s*/, $pattern);
  $pattern_template =~ s|\%|(\.+?)|;
  $pattern_replacement =~ s|\%|\%s|;

  my $result = &expand(&var_perl_from_make($path_in));
  if ($result =~ m|^$pattern_template$|) {
    $result = sprintf($pattern_replacement, &rel_path_canon($1));
    $result = &expand($result);
  } else {
    print STDERR "warning: $pattern_name: $result !~ |^$pattern_template\$|\n";
    die;
  }
  $result = &canon_path($result);
  return $result;
}
sub add_klass_decl {
  my ($file, $klass_name) = @_;
  if ('dk' ne $klass_name) {
    if (!$$file{'klasses'}{$klass_name}) {
      $$file{'klasses'}{$klass_name} = undef;
    }
  }
}
sub add_trait_decl {
  my ($file, $klass_name) = @_;
  if (!$$file{'traits'}{$klass_name}) {
    $$file{'traits'}{$klass_name} = undef;
  }
}
sub add_generic {
  my ($file, $generic) = @_;
  $$file{'generics'}{$generic} = undef;
}
sub remove_generic {
  my ($file, $generic) = @_;
  if (exists $$file{'generics'}{$generic}) {
    delete $$file{'generics'}{$generic};
  }
}
sub add_symbol {
  my ($file, $ident) = @_;
  $ident = &as_literal_symbol_interior($ident);
  $ident = &as_literal_symbol($ident);
  $$file{'symbols'}{$ident} = undef;
}
sub add_keyword {
  my ($file, $ident) = @_;
  $ident = &as_literal_symbol_interior($ident);
  $ident = &as_literal_symbol($ident);
  $$file{'keywords'}{$ident} = undef;
  &add_symbol($file, $ident);
}
sub add_str {
  my ($file, $str) = @_;
  &add_symbol($file, $str);
  $$file{'literal-strs'}{$str} = undef;
}
sub add_int {
  my ($file, $val) = @_;
  my $int = &int_from_str($val);
  $$file{'literal-ints'}{$val}{$int} = undef;
  #&add_symbol($file, $val);
}
sub token_seq::simple_seq {
  my ($tokens) = @_;
  my $seq = [];
  my $tkn;
  for $tkn (@$tokens) {
    &add_last($seq, $$tkn{'str'});
  }
  return $seq;
}
sub warning {
  my ($file, $line, $token_index) = @_;
  printf STDERR "%s:%i: did not expect \'%s\'\n",
    $gbl_filename,
    &sst::line($gbl_sst, $token_index),
    &sst::at($gbl_sst, $token_index);
  printf STDERR "%s:%i: warning/error\n",
    $file,
    $line;
  return;
}
sub error {
  my ($file, $line, $token_index) = @_;
  &warning($file, $line, $token_index);
  exit 1;
}
sub match {
  my ($file, $line, $match_token) = @_;
  if (&sst_cursor::current_token($gbl_sst_cursor) eq $match_token) {
    $$gbl_sst_cursor{'current-token-index'}++;
  } else {
    &sst_cursor::error($gbl_sst_cursor, $$gbl_sst_cursor{'current-token-index'}, "expected '$match_token'");
    &error($file, $line, $$gbl_sst_cursor{'current-token-index'});
  }
  return $match_token;
}
sub match_any {
  #my ($match_token) = @_;
  my $token = &sst_cursor::current_token($gbl_sst_cursor);
  $$gbl_sst_cursor{'current-token-index'}++;
  return $token;
}
sub match_re {
  my ($file, $line, $match_token) = @_;
  if (&sst_cursor::current_token($gbl_sst_cursor) =~ /$match_token/) {
    $$gbl_sst_cursor{'current-token-index'}++;
  } else {
    printf STDERR "%s:%i: expected '%s', but got '%s'\n",
      $file,
      $line,
      $match_token,
      &sst_cursor::current_token($gbl_sst_cursor);
    &error($file, $line, &sst_cursor::current_token($gbl_sst_cursor));
  }
  return &sst::at($$gbl_sst_cursor{'sst'}, $$gbl_sst_cursor{'current-token-index'} - 1);
}
sub exported_header {
  my $tkn = &match_any();
  &match(__FILE__, __LINE__, ';');
}
sub trait {
  my ($args) = @_;
  my ($body, $seq) = &dkdecl('trait');

  if (&sst_cursor::current_token($gbl_sst_cursor) eq ';') {
    $$gbl_root_ast{'traits'}{$body} = undef;
    &match(__FILE__, __LINE__, ';');

    if ($$args{'exported?'}) {
      $$gbl_root_ast{'exported-trait-decls'}{$body} = {};
      $$gbl_current_ast_scope{'exported-trait-decls'} =
        &deep_copy($$gbl_root_ast{'exported-trait-decls'});
    }
    return $body;
  }
  &match(__FILE__, __LINE__, '{');
  my $braces = 1;
  my $previous_scope = $gbl_current_ast_scope;
  my $construct_name = $body;

  if (!defined $$gbl_current_ast_scope{'traits'}{$construct_name}) {
    $$gbl_current_ast_scope{'traits'}{$construct_name}{'defined?'} = 1;
  }
  if ($$args{'exported?'}) {
    $$gbl_current_ast_scope{'traits'}{$construct_name}{'exported?'} = 1;
  }
  $gbl_current_ast_scope = $$gbl_current_ast_scope{'traits'}{$construct_name};
  $$gbl_current_ast_scope{'module'} = $gbl_current_module;
  $$gbl_current_ast_scope{'file'} = $$gbl_sst_cursor{'sst'}{'file'};

  my $attrs = [];
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^initialize$/) {
        &initialize();
        last;
      }
      if (m/^finalize$/) {
        &finalize();
        last;
      }
      if (m/^export$/) {
        &match(__FILE__, __LINE__, 'export');
        for (&sst_cursor::current_token($gbl_sst_cursor)) {
          # [[export]] method
          # [[sentinel]] method
          # [[alias(...)]] method
          if (m/^method$/) {
            $$gbl_root_ast{'traits'}{$construct_name}{'exported?'} = 1; # export trait if any method is exported
            $$gbl_root_ast{'traits'}{$construct_name}{'behavior-exported?'} = 1;
            &method( {'exported?' => 1 });
            last;
          }
        }
      }
      # [[export]] method
      # [[sentinel]] method
      # [[alias(...)]] method
      if (m/^\[$/) {
        &match(__FILE__, __LINE__, '[');
        my $layer = 1;
        if ('[' ne &sst_cursor::current_token($gbl_sst_cursor)) {
          last;
        }
        $attrs = [];
        &add_last($attrs, '[');
        while (0 < $layer) {
          my $current_token = &sst_cursor::current_token($gbl_sst_cursor);
          if (0) {
          } elsif ('[' eq $current_token) {
            &match(__FILE__, __LINE__, '[');
            $layer++;
          } elsif (']' eq $current_token) {
            &match(__FILE__, __LINE__, ']');
            die if 0 == $layer;
            $layer--;
          } else {
            &match_any();
          }
          &add_last($attrs, $current_token);
        }
        last;
      }
      if (m/^method$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '{' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '}' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            ']' eq &sst_cursor::previous_token($gbl_sst_cursor)) { # stmt-boundry
          my $args = { 'exported?' => 0 };
          if (0 < @$attrs) {
            $$args{'attrs'} = &deep_copy($attrs);
            $attrs = [];
            #print &Dumper($$args{'attrs'});
          }
          &method($args);
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!exists $$gbl_current_ast_scope{'traits'}) {
          $$gbl_current_ast_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
         #&add_trait_decl($gbl_root_ast, $trait);
          &add_last($$gbl_current_ast_scope{'traits'}, $trait);
        }
        last;
      }
      if (m/^require$/) {
        my ($body, $seq) = &dkdecl('require');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_ast_scope{'requires'}) {
          $$gbl_current_ast_scope{'requires'} = [];
        }
        &add_last($$gbl_current_ast_scope{'requires'}, &ct($seq));
        last;
      }
      if (m/^provide$/) {
        my ($body, $seq) = &dkdecl('provide');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_ast_scope{'provides'}) {
          $$gbl_current_ast_scope{'provides'} = [];
        }
        &add_last($$gbl_current_ast_scope{'provides'}, &ct($seq));
        last;
      }
      if (m/^\{$/) {
        $braces++;
        &match(__FILE__, __LINE__, '{');
        last;
      }
      if (m/^\}$/) {
        $braces--;
        &match(__FILE__, __LINE__, '}');

        if (0 == $braces) {
          $gbl_current_ast_scope = $previous_scope;
          return;
        }
        last;
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  return;
}
sub slots_seq {
  my ($tkns, $seq) = @_;
  my $type = [];
  my $has_expr = 0;
  foreach my $tkn (@$tkns) {
    if ('=' eq $$tkn{'str'}) {
      $has_expr = 1;
    }
    if (';' ne $$tkn{'str'}) {
      &add_last($type, $$tkn{'str'});
    } else {
      my $expr = [];
      if ($has_expr) {
        while (scalar @$type) {
          &add_first($expr, &remove_last($type));
          if ('=' eq &last($type)) {
            &remove_last($type);
            last;
          }
        }
      }
      my $name = &remove_last($type);
      &add_symbol($gbl_root_ast, $name);
      my $arg_type = &arg::type($type);
      my $slot_info = { 'name' => $name,
                        'type' => $arg_type };
      &add_symbol($gbl_root_ast, $arg_type);
      if (scalar @$expr) {
        $$slot_info{'expr'} = join(' ', @$expr);
      }
      &add_last($seq, $slot_info);
      $has_expr = 0;
      $type = [];
    }
  }
  #print 'slots_seq: ' . &Dumper($seq);
  return;
}
sub enum_seq {
  my ($tkns, $seq) = @_;
  my $expr = [];
  foreach my $tkn (@$tkns) {
    if (',' ne $$tkn{'str'}) {
      &add_last($expr, $$tkn{'str'});
    } else {
      my $name = &remove_first($expr);
      my $slot_info = { 'name' => $name };
      &add_symbol($gbl_root_ast, $name);
      if (scalar @$expr) {
        if ('=' ne &remove_first($expr)) {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        $$slot_info{'expr'} = join(' ', @$expr);
      }
      &add_last($seq, $slot_info);
      $expr = [];
    }
  }
  if (scalar @$expr) {
    my $name = &remove_first($expr);
    my $slot_info = { 'name' => $name };
    &add_symbol($gbl_root_ast, $name);
    if (scalar @$expr) {
      if ('=' ne &remove_first($expr)) {
        die __FILE__, ":", __LINE__, ": error:\n";
      }
      $$slot_info{'expr'} = join(' ', @$expr);
    }
    &add_last($seq, $slot_info);
  }
  #print 'enum_seq: ' . &Dumper($seq);
  return;
}
sub errdump {
  my ($ref) = @_;
  print STDERR Dumper $ref;
}
# slots <array-type>        ;        =>  typealias   slots-t = <array-type>      ;
# slots <func-ptr-type>     ;        =>  typealias   slots-t = <func-ptr-type>   ;

# slots             <>      ;        =>  typealias   slots-t =        <>         ;
# slots struct      <>      ;        =>  typealias   slots-t = struct <>         ;
# slots union       <>      ;        =>  typealias   slots-t = union  <>         ;
# slots enum        <>      ;        =>  typealias   slots-t = enum   <>         ;

# slots                     ;        =>  struct      slots-t                     ;
# slots                     { ... }  =>  struct      slots-t                     { ... }

# slots struct              ;        =>  struct      slots-t                     ;
# slots struct              { ... }  =>  struct      slots-t                     { ... }

# slots union               ;        =>  union       slots-t                     ;
# slots union               { ... }  =>  union       slots-t                     { ... }

# slots enum                ;        =>  enum        slots-t             : int-t ;
# slots enum                { ... }  =>  enum        slots-t             : int-t { ... }
#
# slots enum           : <> ;        =>  enum        slots-t             : <>    ;
# slots enum           : <> { ... }  =>  enum        slots-t             : <>    { ... }

# slots type-enum           ;        =>  enum struct slots-t                     ;
# slots type-enum           { ... }  =>  enum struct slots-t                     { ... }
#
# slots type-enum      : <> ;        =>  enum struct slots-t             : <>    ;
# slots type-enum      : <> { ... }  =>  enum struct slots-t             : <>    { ... }

my $enum_set = { 'enum'      => 1,
                 'type-enum' => 1 };
sub slots {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'slots');
  if ($$args{'exported?'}) {
    $$gbl_current_ast_scope{'slots'}{'exported?'} = 1;
  }
  # slots are always in same module as klass
  $$gbl_current_ast_scope{'slots'}{'module'} = $$gbl_current_ast_scope{'module'};

  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor) &&
         '{' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &add_last($type, $tkn);
  }
  my $aggr_set = { 'struct'    => 1,
                   'union'     => 1,
                   'type-enum' => 1,
                   'enum'      => 1 };
  my $cat = 'struct';
  if (@$type && 3 <= @$type) {
    if ($$enum_set{&first($type)}) {
      my $enum_base = [splice(@$type, 2, scalar(@$type) - 1)];
      my $tkn =    &remove_last($type);
      die if ':' ne $tkn; # not key/element delim
      $$gbl_current_ast_scope{'slots'}{'enum-base'} = $enum_base;
      &add_symbol($gbl_root_ast, join('', @$enum_base));
      #print STDERR &Dumper($$gbl_current_ast_scope{'slots'});
    }
  }
  if (@$type && 1 == @$type) {
    if ($$aggr_set{&first($type)}) {
      if ($$enum_set{&first($type)}) {
        &add_symbol($gbl_root_ast, 'enum-info');
        &add_symbol($gbl_root_ast, 'const-info');

        &add_klass_decl($gbl_root_ast, 'enum-info');
        &add_klass_decl($gbl_root_ast, 'named-enum-info');
        &add_klass_decl($gbl_root_ast, 'const-info');
      }
      $cat = &remove_first($type);
      $$gbl_current_ast_scope{'slots'}{'cat'} = $cat;
    }
  }
  if (@$type) {
    my $arg_type = &arg::type($type);
    &add_symbol($gbl_root_ast, &remove_extra_whitespace($arg_type));
    $$gbl_current_ast_scope{'slots'}{'type'} = $arg_type;
  } else {
    $$gbl_current_ast_scope{'slots'}{'cat'} = $cat;
  }
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      return;
    }
    if (m/^\{$/) {
      if (@$type) {
        &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
      }
      $$gbl_current_ast_scope{'slots'}{'cat-info'} = [];
      $$gbl_current_ast_scope{'slots'}{'file'} = $$gbl_sst_cursor{'sst'}{'file'};
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      if ($open_curley_index + 1 != $close_curley_index) {
        my $slots_defs = &sst::token_seq($gbl_sst, $open_curley_index + 1, $close_curley_index - 1);
        if ($$enum_set{$cat}) {
          &enum_seq($slots_defs, $$gbl_current_ast_scope{'slots'}{'cat-info'});
        } else {
          &slots_seq($slots_defs, $$gbl_current_ast_scope{'slots'}{'cat-info'});
        }
      }
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      &add_symbol($gbl_root_ast, 'size');
      return;
    }
    &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  }
  &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  return;
}
sub const {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'const');
  if (!exists $$gbl_current_ast_scope{'const'}) {
    $$gbl_current_ast_scope{'const'} = [];
  }
  my $const = {};
  if ($$args{'exported?'}) {
    $$const{'exported?'} = 1;
  }
  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &add_last($type, $tkn);
  }
  my $rhs = [];
  if (&ct($type) =~ m/=/) {
    while ('=' ne &last($type)) {
      &add_first($rhs, &remove_last($type));
    }
    &remove_last($type); # '='
  }
  my $name = &remove_last($type);
  &add_symbol($gbl_root_ast, $name); # const var name
  if (@$type) {
    $$const{'type'} = &arg::type($type);
    $$const{'name'} = $name;
    $$const{'rhs'} = $rhs;
  }
  if (';' eq &sst_cursor::current_token($gbl_sst_cursor)) {
    &match(__FILE__, __LINE__, ';');
    &add_last($$gbl_current_ast_scope{'const'}, $const);
    return;
  }
}
sub enum {
  my ($args) = @_;
  my $cat = &match_re(__FILE__, __LINE__, 'type-enum|enum');
  if (!exists $$gbl_current_ast_scope{$cat}) {
    $$gbl_current_ast_scope{$cat} = [];
  }
  my $enum = {};
  if ($$args{'exported?'}) {
    $$enum{'exported?'} = 1;
  }
  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor) &&
         '{' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &add_last($type, $tkn);
  }
  if (@$type) {
    $$enum{'type'} = &arg::type($type);
  }
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      &add_last($$gbl_current_ast_scope{$cat}, $enum);
      return;
    }
    if (m/^\{$/) {
      if (@$type) {
        $$enum{'type'} = $type;
      }
      $$enum{'cat-info'} = [];
      my ($open_curley_index, $close_curley_index) =
        &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      if ($open_curley_index + 1 != $close_curley_index) {
        my $enum_defs = &sst::token_seq($gbl_sst,
                                        $open_curley_index + 1,
                                        $close_curley_index - 1);
        &enum_seq($enum_defs, $$enum{'cat-info'});
      }
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      &add_symbol($gbl_root_ast, 'enum-info');
      &add_symbol($gbl_root_ast, 'const-info');

      &add_klass_decl($gbl_root_ast, 'enum-info');
      &add_klass_decl($gbl_root_ast, 'named-enum-info');
      &add_klass_decl($gbl_root_ast, 'const-info');
      &add_last($$gbl_current_ast_scope{$cat}, $enum);
      return;
    }
    &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  }
  &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  return;
}
sub initialize {
  &match(__FILE__, __LINE__, 'initialize');
  if ('(' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    return;
  }
  &match(__FILE__, __LINE__, '(');
  if ('object-t' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    return;
  }
  &match(__FILE__, __LINE__, 'object-t');
  if (&sst_cursor::current_token($gbl_sst_cursor) =~ m/$id/) {
    &match_any();
    #&match(__FILE__, __LINE__, 'klass');
  }
  &match(__FILE__, __LINE__, ')');
  &match(__FILE__, __LINE__, '->');
  &match(__FILE__, __LINE__, 'void');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root_ast, 'initialize');
      $$gbl_current_ast_scope{'has-initialize'} = 1;
      my ($open_curley_index, $close_curley_index) =
        &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      last;
    }
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      last;
    }
    &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  }
  return;
}
sub finalize {
  &match(__FILE__, __LINE__, 'finalize');
  if ('(' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    return;
  }
  &match(__FILE__, __LINE__, '(');
  if ('object-t' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    return;
  }
  &match(__FILE__, __LINE__, 'object-t');
  if (&sst_cursor::current_token($gbl_sst_cursor) =~ m/$id/) {
    &match_any();
    #&match(__FILE__, __LINE__, 'klass');
  }
  &match(__FILE__, __LINE__, ')');
  &match(__FILE__, __LINE__, '->');
  &match(__FILE__, __LINE__, 'void');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root_ast, 'finalize');
      $$gbl_current_ast_scope{'has-finalize'} = 1;
      my ($open_curley_index, $close_curley_index) =
        &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      last;
    }
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      last;
    }
    &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  }
  return;
}
sub fragment_str {
  my ($arg) = @_;
  my $argstr = join(' ', @$arg);
  $argstr = &remove_extra_whitespace($argstr);
  return $argstr;
}
# include-for <...>|"..." type1 [, type2 ...] ;
# include-for <sys/socket.h> struct sockaddr, struct sockproto ;
my $last_for_first = { '<' => '>',
                       '"' => '"' };
sub include_for {
  my $seq = &dkdecl('include-for');
  my $index = 0;
  my $last = $$last_for_first{$$seq[0]};
  foreach my $part (@$seq) {
    last if $last eq $part;
    $index++;
  }
  my $header_seq = [splice @$seq, 0, $index + 1];
  my $header = &ct($header_seq);
  my $types_str = &remove_extra_whitespace(join(' ', @$seq));
  $types_str =~ s/\s+/ /g;
  my $types = [split(/\s*,\s*/, $types_str)];
  my $abbrev_types = [];
  if (0) {
    foreach my $type (@$types) {
      if ($type =~ /^(class|struct|union|enum)\s/) {
        my $abbrev_type = $type =~ s/^(class|struct|union|enum)\s//r;
        &add_last($abbrev_types, $abbrev_type);
      }
    }
  }
  foreach my $type (@$types, @$abbrev_types) {
    $$gbl_root_ast{'include-fors'}{$type}{$header} = 1;
  }
}
sub module_decl {
  &match(__FILE__, __LINE__, 'module');
  my $module_name = &match_re(__FILE__, __LINE__, $id);
  &match(__FILE__, __LINE__, ';');
  $gbl_current_module = $module_name;
}
sub module_import_defn {
  my $depth = 0;
  &match(__FILE__, __LINE__, 'import');
  my $module_name = &match_re(__FILE__, __LINE__, $id);
  $gbl_current_module = $module_name;
  &match(__FILE__, __LINE__, '{');
  $depth++;
  my $dqstr = &dqstr_regex();

  my $tbl = {};
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (0) {
      } elsif (m/^\{$/) {
        $depth++;
      } elsif (m/^\}$/) {
        die if 0 == $depth;
        $depth--;
        if (0 == $depth) {
          &match(__FILE__, __LINE__, '}');
          $$gbl_root_ast{'modules'}{$gbl_current_module}{'import'} = $tbl;
          return;
        } else {
          die;
        }
      } elsif (m/^self$/) {
        my $lhs = &match(__FILE__, __LINE__, $_);
        my $rhs = &match_re(__FILE__, __LINE__, $dqstr);
        $rhs =~ s/^"(.+)"$/$1/;
        &match(__FILE__, __LINE__, ';');
        if (defined $$tbl{'self'}) {
          die;
        }
        $$tbl{'self'} = $rhs;
      } elsif (m/^source$/) {
        my $lhs = &match(__FILE__, __LINE__, $_);
        my $rhs = &match_re(__FILE__, __LINE__, $dqstr);
        $rhs =~ s/^"(.+)"$/$1/;
        &match(__FILE__, __LINE__, ';');
        if (!exists $$tbl{'sources'}) {
          $$tbl{'sources'} = [];
        }
        &add_last($$tbl{'sources'}, $rhs);
      } elsif (m/^shared-library$/) {
        my $lhs = &match(__FILE__, __LINE__, $_);
        my $rhs = &match_re(__FILE__, __LINE__, $dqstr);
        $rhs =~ s/^"(.+)"$/$1/;
        &match(__FILE__, __LINE__, ';');
        if (!exists $$tbl{'shared-libraries'}) {
          $$tbl{'shared-libraries'} = [];
        }
        $rhs =~ s/\$\(so_ext\)/$so_ext/;
        &add_last($$tbl{'shared-libraries'}, $rhs);
      } elsif (m/^module$/) {
        my $lhs = &match(__FILE__, __LINE__, $_);
        my $rhs = &match_re(__FILE__, __LINE__, $id);
        &match(__FILE__, __LINE__, ';');
        if (!exists $$tbl{'modules'}) {
          $$tbl{'modules'} = [];
        }
        &add_last($$tbl{'modules'}, $rhs);
      } else {
        die;
      }
    }
  }
}
sub module_export_defn {
  my $depth = 0;
  &match(__FILE__, __LINE__, 'export');
  my $module_name = &match_re(__FILE__, __LINE__, $id);
  $gbl_current_module = $module_name;
  &match(__FILE__, __LINE__, '{');
  $depth++;

  my $tbl = {};
  my $seq = [];
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (0) {
      } elsif (m/^\{$/) {
        $depth++;
        &add_last($seq, $_);
      } elsif (m/^\}$/) {
        die if 0 == $depth;
        $depth--;
        if (0 == $depth) {
          &match(__FILE__, __LINE__, '}');
          if (scalar @$seq) {
            my $seqstr = &fragment_str($seq);
            $$tbl{$seqstr} = $seq;
            $seq= [];
          }
          $$gbl_root_ast{'modules'}{$gbl_current_module}{'export'} = $tbl;
          return;
        } elsif (1 == $depth) {
          &add_last($seq, $_);
          my $seqstr = &fragment_str($seq);
          $$tbl{$seqstr} = $seq;
          $seq= [];
        } else {
          die;
        }
      } elsif (m/^;$/) {
        if (1 == $depth) {
          my $seqstr = &fragment_str($seq);
          $$tbl{$seqstr} = $seq;
          $seq= [];
        } else {
          &add_last($seq, $_);
        }
      } else {
        &add_last($seq, $_);
      }
      &match_any();
    }
  }
}
sub interpose {
  my ($args) = @_;
  my $seq = &dkdecl_list('interpose');
  my $first = &remove_first($seq);
  if ($$gbl_root_ast{'interposers'}{$first}) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  if ($$gbl_root_ast{'interposers-unordered'}{$first}) {
    # check for sameness here
    delete $$gbl_root_ast{'interposers-unordered'}{$first};
  }
  $$gbl_root_ast{'interposers'}{$first} = $seq;
}
# this works for methods because zero or one params are allowed, so comma is not seen in a a param list
sub match_qual_ident {
  my ($file, $line) = @_;
  my $seq = [];
  while (&sst_cursor::current_token($gbl_sst_cursor) ne ',' &&
         &sst_cursor::current_token($gbl_sst_cursor) ne ';') {
    my $token = &match_any();
    &add_last($seq, $token);
  }
  if (0 == @$seq) {
    $seq = undef;
  }
  return $seq;
}
sub klass {
  my ($args) = @_;
  my ($body, $seq) = &dkdecl('klass');

  if (&sst_cursor::current_token($gbl_sst_cursor) eq ';') {
    $$gbl_root_ast{'klasses'}{$body} = undef;
    &match(__FILE__, __LINE__, ';');

    if ($$args{'exported?'}) {
      $$gbl_root_ast{'exported-klass-decls'}{$body} = {};
      $$gbl_current_ast_scope{'exported-klass-decls'} =
        &deep_copy($$gbl_root_ast{'exported-klass-decls'});
    }
    return $body;
  }
  &match(__FILE__, __LINE__, '{');
  my $braces = 1;
  my $previous_scope = $gbl_current_ast_scope;
  my $construct_name = $body;

  if (!defined $$gbl_current_ast_scope{'klasses'}{$construct_name}) {
    $$gbl_current_ast_scope{'klasses'}{$construct_name}{'defined?'} = 1;
  }
  if ($$args{'exported?'}) {
    $$gbl_current_ast_scope{'klasses'}{$construct_name}{'exported?'} = 1;
  }
  $gbl_current_ast_scope = $$gbl_current_ast_scope{'klasses'}{$construct_name};
  $$gbl_current_ast_scope{'module'} = $gbl_current_module;
  $$gbl_current_ast_scope{'file'} = $$gbl_sst_cursor{'sst'}{'file'};

  my $attrs = [];
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^initialize$/) {
        &initialize();
        last;
      }
      if (m/^finalize$/) {
        &finalize();
        last;
      }
      if (m/^export$/) {
        &match(__FILE__, __LINE__, 'export');
        for (&sst_cursor::current_token($gbl_sst_cursor)) {
          if (m/^const$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root_ast{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either enums or slots or methods are exported
              &const({ 'exported?' => 1 });
              last;
            }
          }
          if (m/^enum$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root_ast{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either enums or slots or methods are exported
              &enum({ 'exported?' => 1 });
              last;
            }
          }
          if (m/^slots$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root_ast{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either slots or methods are exported
              &slots({ 'exported?' => 1 });
              last;
            }
          }
          # [[export]] method
          # [[sentinel]] method
          # [[alias(...)]] method
          if (m/^method$/) {
            $$gbl_root_ast{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either slots or methods are exported
            $$gbl_root_ast{'klasses'}{$construct_name}{'behavior-exported?'} = 1;
            &method({ 'exported?' => 1 });
            last;
          }
        }
        last;
      }
      if (m/^slots$/) {
        if (&sst_cursor::next_token($gbl_sst_cursor) !~ /^(\.|->|,|\+)$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) || '{' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &slots({ 'exported?' => $$args{'exported?'} });
          last;
        }
        }
      }
      # [[export]] method
      # [[sentinel]] method
      # [[alias(...)]] method
      if (m/^\[$/) {
        &match(__FILE__, __LINE__, '[');
        my $layer = 1;
        if ('[' ne &sst_cursor::current_token($gbl_sst_cursor)) {
          last;
        }
        $attrs = [];
        &add_last($attrs, '[');
        while (0 < $layer) {
          my $current_token = &sst_cursor::current_token($gbl_sst_cursor);
          if (0) {
          } elsif ('[' eq $current_token) {
            &match(__FILE__, __LINE__, '[');
            $layer++;
          } elsif (']' eq $current_token) {
            &match(__FILE__, __LINE__, ']');
            die if 0 == $layer;
            $layer--;
          } else {
            &match_any();
          }
          &add_last($attrs, $current_token);
        }
        last;
      }
      if (m/^method$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '{' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '}' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            ']' eq &sst_cursor::previous_token($gbl_sst_cursor)) { # stmt-boundry
          my $args = { 'exported?' => 0 };
          if (0 < @$attrs) {
            $$args{'attrs'} = &deep_copy($attrs);
            $attrs = [];
            #print &Dumper($$args{'attrs'});
          }
          &method($args);
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!exists $$gbl_current_ast_scope{'traits'}) {
          $$gbl_current_ast_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
          &add_trait_decl($gbl_root_ast, $trait);
          &add_last($$gbl_current_ast_scope{'traits'}, $trait);
        }
        last;
      }
      if (m/^require$/) {
        my ($body, $seq) = &dkdecl('require');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_ast_scope{'requires'}) {
          $$gbl_current_ast_scope{'requires'} = [];
        }
        my $path = &ct($seq);
        &add_last($$gbl_current_ast_scope{'requires'}, $path);
        &add_klass_decl($gbl_root_ast, $path);
        last;
      }
      if (m/^provide$/) {
        my ($body, $seq) = &dkdecl('provide');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_ast_scope{'provides'}) {
          $$gbl_current_ast_scope{'provides'} = [];
        }
        my $path = &ct($seq);
        &add_last($$gbl_current_ast_scope{'provides'}, $path);
        &add_klass_decl($gbl_root_ast, $path);
        last;
      }
      if (m/^interpose$/) {
        my ($body, $seq) = &dkdecl('interpose');
        &match(__FILE__, __LINE__, ';');
        my $name = &ct($seq);
        $$gbl_current_ast_scope{'interpose'} = $name;
        &add_klass_decl($gbl_root_ast, $name);

        if (!$$gbl_root_ast{'interposers'}{$name} &&
            !$$gbl_root_ast{'interposers-unordered'}{$name}) {
          $$gbl_root_ast{'interposers'}{$name} = [];
          &add_last($$gbl_root_ast{'interposers'}{$name}, $construct_name);
        } elsif ($$gbl_root_ast{'interposers'}{$name}) {
          $$gbl_root_ast{'interposers-unordered'}{$name} = $$gbl_root_ast{'interposers'}{$name};
          delete $$gbl_root_ast{'interposers'}{$name};
          &add_last($$gbl_root_ast{'interposers-unordered'}{$name}, $construct_name);
        } else {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        last;
      }
      if (m/^superklass$/) {
        if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$id/) {
              my ($body, $seq) = &dkdecl('superklass');
              &match(__FILE__, __LINE__, ';');
              my $path = &ct($seq);
              $$gbl_current_ast_scope{'superklass'} = $path;
              &add_klass_decl($gbl_root_ast, $path);
              last;
            }
          }
        }
      }
      if (m/^klass$/) {
        if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$' &&
            &sst_cursor::previous_token($gbl_sst_cursor) ne '::') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$id/) {
              my ($body, $seq) = &dkdecl('klass');
              &match(__FILE__, __LINE__, ';');
              my $path = &ct($seq);
              $$gbl_current_ast_scope{'klass'} = $path;
              &add_klass_decl($gbl_root_ast, $path);
              last;
            }
          }
        }
      }
      if (m/^\{$/) {
        $braces++;
        &match(__FILE__, __LINE__, '{');
        last;
      }
      if (m/^\}$/) {
        $braces--;
        &match(__FILE__, __LINE__, '}');

        if (0 == $braces) {
          $gbl_current_ast_scope = $previous_scope;
          return &ct($seq);
        }
        last;
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  return &ct($seq);
}
sub dkdecl {
  my ($tkn) = @_;
  &match(__FILE__, __LINE__, $tkn);
  my $parts = [];

  while (&sst_cursor::current_token($gbl_sst_cursor) ne ';' &&
         &sst_cursor::current_token($gbl_sst_cursor) ne '{') {
    &add_last($parts, &sst_cursor::current_token($gbl_sst_cursor));
    $$gbl_sst_cursor{'current-token-index'}++;
  }

  #    if ('::' ne $parts[0])
  #    {
  #        &add_first($parts, '::');
  #    }
  my $body = &ct($parts);
  return ($body, $parts);
}
sub dkdecl_peek {
  my ($tkn) = @_;
  my ($body, $parts) = &dkdecl($tkn);
  my $de = &sst_cursor::current_token($gbl_sst_cursor); # ; or {
  $$gbl_sst_cursor{'current-token-index'} -= (scalar @$parts + 1);
  return ($body, $parts, $de);
}
sub dkdecl_list {
  my ($tkn) = @_;
  &match(__FILE__, __LINE__, $tkn);
  my $parts = [];
  my $body = '';

  while (&sst_cursor::current_token($gbl_sst_cursor) ne ';' &&
         &sst_cursor::current_token($gbl_sst_cursor) ne '{') {
    if (',' ne &sst_cursor::current_token($gbl_sst_cursor)) {
      $body .= &sst_cursor::current_token($gbl_sst_cursor);
      #my $token = &match_any($gbl_sst);
    } else {
      #&match(__FILE__, __LINE__, ',');
      &add_last($parts, $body);
      $body = '';
    }
    $$gbl_sst_cursor{'current-token-index'}++;
  }
  &add_last($parts, $body);
  return $parts;
}
sub expand_type {
  my ($type) = @_;
  my $previous_token = '';

  for (my $i = 0; $i < @$type; $i++) {
    $previous_token = $$type[$i];
  }
  if (1 < @$type &&
      $$type[@$type - 1] =~ /$id/) {
    &remove_last($type);
  }
  return $type;
}
sub split_seq {
  my ($tkns, $delimiter) = @_;
  my $tkn;
  my $result = [];
  my $i = 0;
  $$result[$i] = [];

  foreach $tkn (@$tkns) {
    if ($delimiter eq $tkn) {
      $i++;
      $$result[$i] = [];
    } else {
      &add_last($$result[$i], $tkn);
    }
  }
  return $result;
}
sub types {
  my ($tokens) = @_;
  my $result = &split_seq($tokens, ',');

  for (my $j = 0; $j < @$result; $j++) {
    $$result[$j] = &expand_type($$result[$j]);
  }
  return $result;
}
sub kw_arg_offsets {
  my ($seq, $gbl_token) = @_;
  my $opens = 0;
  # start at 2 since type and name preceed colon
  for (my $i = 2; $i < @$seq; $i++) {
    # we don't want to find a colon inside a block or func call
    if ($$seq[$i] =~ /^\{|\($/) {
      $opens++;
    } elsif ($$seq[$i] =~ /^\}|\)$/) {
      if (0 == $opens) {
        &sst_cursor::error($gbl_sst_cursor, $$gbl_sst_cursor{'current-token-index'}, "unbalenced {} or ()");
      }
      $opens--;
    }
    if (0 == $opens) {
      if ($colon eq $$seq[$i]) {
        return $i;
      }
    }
  }
  return 0; # illegal offset value since type and name preceed colon
}
sub param_list {
  my ($param_types) = @_;
  #print STDERR Dumper $param_types;
  my $params = [];
  my $param_token;
  my $len = @$param_types;
  my $i = 0;
  while ($i < $len) {
    my $param_n = [];
    my $opens = 0;
    while ($i < $len) {
      for ($$param_types[$i]) {
        if (m/^\,$/) {
          if ($opens) {
            &add_last($param_n, $$param_types[$i]);
            $i++;
          } else {
            $i++;
            &add_last($params, $param_n);
            $param_n = [];
            next;
          }
        } elsif (m/^\{|\($/) {
          $opens++;
          &add_last($param_n, $$param_types[$i]);
          $i++;
        } elsif (m/^\)|\}$/) {
          $opens--;
          &add_last($param_n, $$param_types[$i]);
          $i++;
        } else {
          &add_last($param_n, $$param_types[$i]);
          $i++;
        }
      }
    }
    $i++;
    &add_last($params, $param_n);
  }
  #print STDERR Dumper $params;
  my $types = [];
  my $kw_arg_names = [];
  my $kw_arg_defaults = [];
  foreach my $type (@$params) {
    if (':' eq $$type[-1]) {
      &add_last($type, split('', $$kw_arg_placeholders{'nodefault'}));
    }
    my $colon_offset = &kw_arg_offsets($type);

    if ($colon_offset) {
      my $kw_args_name = $colon_offset - 1;
      my $kw_args_default = [splice(@$type, $colon_offset)];
      my $colon_tkn = &remove_first($kw_args_default);
      my $kw_arg_nodefault_placeholder = $$kw_arg_placeholders{'nodefault'};
      my $kw_arg_nodefault_placeholder_tkns = [split('', $kw_arg_nodefault_placeholder)]; # assume no multi-character tokens (dangerous)
      if (scalar @$kw_arg_nodefault_placeholder_tkns == scalar @$kw_args_default) {
        my $is_default = 0;
        for (my $i = 0; $i < @$kw_arg_nodefault_placeholder_tkns; $i++) {
          if ($$kw_arg_nodefault_placeholder_tkns[$i] ne $$kw_args_default[$i]) {
            $is_default = 1;
            last;
          }
        }
        if ($is_default) {
          &add_last($kw_arg_defaults, $kw_args_default);
        }
      } else {
        &add_last($kw_arg_defaults, $kw_args_default);
      }
      my $kw_args_name_str = $$type[$kw_args_name];
      &add_keyword($gbl_root_ast, $kw_args_name_str);
      my $kw_args_name_seq = [splice(@$type, $kw_args_name)];
      #print STDERR Dumper $kw_args_name_seq;
      #print STDERR Dumper $type;
      &add_last($kw_arg_names, &remove_last($kw_args_name_seq));
    } else {
      my $ident = &remove_last($type);
      if ($ident =~ m/\-t$/) {
        &add_last($type, $ident);
      } elsif (!($ident =~ m/$id/)) {
        &add_last($type, $ident);
      }
    }
    &add_last($types, $type);
  }

  if (0 == @$kw_arg_names) {
    $kw_arg_names = undef;
  }

  if (0 == @$kw_arg_defaults) {
    $kw_arg_defaults = undef;
  }
  return ($types, $kw_arg_names, $kw_arg_defaults);
}
sub add_klasses_used { # not currently used
  my ($scope, $gbl_sst_cursor) = @_;
  my $seqs = $$gbl_used{'used-klasses'};
  my $size = &sst_cursor::size($gbl_sst_cursor);
  for (my $i = 0; $i < $size - 2; $i++) {
    my $first_index = $$gbl_sst_cursor{'first-token-index'} || 0;
    my $last_index = $$gbl_sst_cursor{'last-token-index'} || undef;
    my $new_sst_cursor = &sst_cursor::make($$gbl_sst_cursor{'sst'}, $first_index + $i, $last_index);

    foreach my $args (@$seqs) {
      my ($range, $matches) = &sst_cursor::match_pattern_seq($new_sst_cursor, $$args{'pattern'});
      if ($range) {
        my $adjusted_range = [ $$range[0], $$range[1] - 2 ]; # remove :: tkn
        my $name = &sst_cursor::str($new_sst_cursor, $adjusted_range);
        if (0) {
          my $prev_indent = $Data::Dumper::Indent;
          $Data::Dumper::Indent = 0;

          if ($$gbl_sst_cursor{'file'}) {
            print "FILE: " . $$gbl_sst_cursor{'file'} . $nl;
          }
          print "RANGE: " . &Dumper($range) . ", MATCHES: " . &Dumper($matches) . ", NAME: " . $name . $nl;
          $Data::Dumper::Indent = $prev_indent;
        }
        &add_klass_decl($gbl_root_ast, $name);
      }
    }
  }
}
sub add_all_generics_used {
  my ($gbl_sst_cursor, $scope, $args) = @_;
  my ($range, $matches) = &sst_cursor::match_pattern_seq($gbl_sst_cursor, $$args{'pattern'});
  if ($range) {
    my $name = &sst_cursor::str($gbl_sst_cursor, $$args{'range'});
    $name =~ s/^\$//;
    $$scope{$$args{'name'}}{$name} = undef;
    #&errdump($range);
    #&errdump($matches);
  }
}
sub add_generics_used {
  my ($scope, $gbl_sst_cursor) = @_;
  #print STDERR &sst::filestr($$gbl_sst_cursor{'sst'});
  #&errdump($$gbl_sst_cursor{'sst'});
  my $seqs = $$gbl_used{'used-generics'};
  my $size = &sst_cursor::size($gbl_sst_cursor);
  for (my $i = 0; $i < $size - 2; $i++) {
    my $first_index = $$gbl_sst_cursor{'first-token-index'} || 0;
    my $last_index = $$gbl_sst_cursor{'last-token-index'} || undef;
    my $new_sst_cursor = &sst_cursor::make($$gbl_sst_cursor{'sst'}, $first_index + $i, $last_index);

    foreach my $seq (@$seqs) {
      &add_all_generics_used($new_sst_cursor, $scope, $seq);
    }
  }
  #print STDERR &sst::filestr($$gbl_sst_cursor{'sst'});
}
sub kw_args_generics_add {
  my ($target_srcs_ast, $method) = @_;
  my ($name, $types) = &kw_args_method_sig($method);
  my $name_str =  &str_from_seq($name);
  my $types_str = &param_types_str($types);
  $$target_srcs_ast{'kw-arg-generics'}{$name_str}{$types_str} = [ $name, $types ];
}

# 'methods'
# 'slots-methods'

# exported or not, slots or not, va or not

# exported-va-slots-methods
sub method {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'method');
  my $method = {};
  if ($$args{'exported?'}) {
    $$method{'exported?'} = 1;
  }
  if ($$args{'attrs'}) {
    #print &Dumper($$args{'attrs'});
    my $attrs = &ct($$args{'attrs'});
    my ($attr, $attr_arg);
    if ($attrs =~ /^\[\[\s*([\w-]+)\s*\(\s*([\w-]+)\s*\)\s*\]\]$/) {
      ($attr, $attr_arg) = ($1, $2);

      if (0) {
      } elsif ('alias' eq $attr) {
        $$method{'alias'} = [ $attr_arg ];
      } elsif ('format-printf' eq $attr || 'format-va-printf' eq $attr) {
        if (!exists $$method{'attributes'}) {
          $$method{'attributes'} = [];
        }
        &add_last($$method{'attributes'}, $attr);
      }
    }
  }
  my $is_va = 0;
  my $name = [];
  &add_last($name, &match_re(__FILE__, __LINE__, '[\w-]+'));
  if ('va' eq $$name[0]) {
    $is_va = 1;
    &add_last($name, &match(__FILE__, __LINE__, '::'));
    &add_last($name, &match_re(__FILE__, __LINE__, '[\w-]+'));
  }
  my ($open_paren_index, $close_paren_index)
    = &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);

  if ($close_paren_index == $open_paren_index + 1) {
    # METHOD ALIAS
    &match(__FILE__, __LINE__, '(');
    # this must be empty!
    &match(__FILE__, __LINE__, ')');
    &match(__FILE__, __LINE__, '=>');
    my $realname = [];
    &add_last($realname, &match_re(__FILE__, __LINE__, '[\w-]+'));
    if ($is_va) {
      &add_last($realname, &match(__FILE__, __LINE__, '::'));
      &add_last($realname, &match_re(__FILE__, __LINE__, '[\w-]+'));
    }
    my ($open_index, $close_index)
      = &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
    if ($close_index > $open_index + 1) {
      die "Time to support aliasing of overloaded methods.";
    }
    &match(__FILE__, __LINE__, '(');
    &match(__FILE__, __LINE__, ')');
    &match(__FILE__, __LINE__, ';');
    $$method{'alias'} = $realname;
    $$method{'name'} = $name;
    ###&add_generic($gbl_root_ast, &ct($$method{'name'}));
    return;
  } else {
    $$method{'name'} = $name;
    &add_generic($gbl_root_ast, &ct($$method{'name'}));
  }
  if ('object-t' eq &sst::at($gbl_sst, $open_paren_index + 1)) {
    if (',' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1) &&
        ')' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1)) {
      if ('self' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1)) {
        &error(__FILE__, __LINE__, $open_paren_index + 1 + 1);
      }
    }
  }
  if ($open_paren_index + 1 == $close_paren_index) {
    &error(__FILE__, __LINE__, $close_paren_index);
  }
  my $param_types = &sst::token_seq($gbl_sst,
                                        $open_paren_index + 1,
                                        $close_paren_index - 1);
  $param_types = &token_seq::simple_seq($param_types);
  my ($kw_arg_param_types, $kw_arg_names, $kw_arg_defaults) =
    &param_list($param_types);
  $$method{'param-types'} = $kw_arg_param_types;
  # if method has kw-arg-names, then its a kw arg
  # but it could still be a kw arg

  if ($kw_arg_names) {
    my $method_name = &str_from_seq($$method{'name'});
    $$method{'kw-arg-names'} = $kw_arg_names;
    if ($kw_arg_defaults) {
      $$method{'kw-arg-defaults'} = $kw_arg_defaults;
    }
    &kw_args_generics_add($gbl_root_ast, $method);
  }
  $$gbl_sst_cursor{'current-token-index'} = $close_paren_index + 1;

  #print STDERR &Dumper($method);
  &match(__FILE__, __LINE__, '->'); # this syntax is similiar to how Lambda funcs are specified in C++11

  ### RETURN-TYPE
  my $return_type = [];
  while (&sst::at($$gbl_sst_cursor{'sst'},
                  $$gbl_sst_cursor{'current-token-index'}) !~ m/^(\;|\{)$/) {
    &add_last($return_type, &match_any());
  }
  if ('void' eq &ct($return_type)) {
    $$method{'return-type'} = undef;
    &warning(__FILE__, __LINE__,
             $$gbl_sst_cursor{'current-token-index'}); # 'void' is not a recommended return type for a method
  } else {
    $$method{'return-type'} = $return_type;
  }
  #print STDERR &Dumper($method);

  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      $$method{'defined?'} = 1;
      $$method{'module'} = $gbl_current_module;
      my ($open_curley_index, $close_curley_index) =
        &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      my $block_sst_cursor = &sst_cursor::make($gbl_sst,
                                               $open_curley_index,
                                               $close_curley_index);
      #&errdump($block_sst_cursor);
      #&add_generics_used($method, $block_sst_cursor);
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      last;
    }
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      last;
    }
    &error(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
  }
  my $signature = &func::overloadsig($method, undef);

  if (0) {
  } elsif (&is_slots($method) &&
           &is_va($method)) { # 11
    if (!defined $$gbl_current_ast_scope{'slots-methods'}) {
      $$gbl_current_ast_scope{'slots-methods'} = {};
    }
    $$gbl_current_ast_scope{'slots-methods'}{$signature} = $method;
  } elsif (&is_slots($method) &&
          !&is_va($method)) { # 10
    if (!defined $$gbl_current_ast_scope{'slots-methods'}) {
      $$gbl_current_ast_scope{'slots-methods'} = {};
    }
    $$gbl_current_ast_scope{'slots-methods'}{$signature} = $method;
  } elsif (!&is_slots($method) &&
            &is_va($method)) { # 01
    if (!defined $$gbl_current_ast_scope{'methods'}) {
      $$gbl_current_ast_scope{'methods'} = {};
    }
    $$gbl_current_ast_scope{'methods'}{$signature} = $method;
  } elsif (!&is_slots($method) &&
           !&is_va($method)) { # 00
    if (!defined $$gbl_current_ast_scope{'methods'}) {
      $$gbl_current_ast_scope{'methods'} = {};
    }
    $$gbl_current_ast_scope{'methods'}{$signature} = $method;
  }
  return;
}
my $_target_inputs_ast;
sub target_inputs_ast {
  my ($asts, $is_precompile) = @_;
  return $_target_inputs_ast if $_target_inputs_ast;
  my $target_inputs_ast_path = &target_builddir() . '/inputs.ast';
  if ($is_precompile && -e $target_inputs_ast_path) {
    $_target_inputs_ast = &scalar_from_file($target_inputs_ast_path);
    return $_target_inputs_ast;
  }
  die if !$asts;
  if (0) { print STDERR "target_inputs_ast()" . $nl; }
  #my $reinit = 0;
  #if ($_target_inputs_ast) { $reinit = 1; }
  #if ($reinit) { print STDERR &Dumper([keys %{$$_target_inputs_ast{'klasses'}}]); }
  my $should_translate;
  $_target_inputs_ast = &ast_merge($target_inputs_ast_path, $asts, $should_translate = 1);
  #if ($reinit) { print STDERR &Dumper([keys %{$$_target_inputs_ast{'klasses'}}]); }
  return $_target_inputs_ast;
}
sub generics::klass_type_from_klass_name { ###
  my ($klass_name) = @_;
  my $target_inputs_ast = &target_inputs_ast();
  my $cmd_info = &root_cmd();
  my $klass_type;

  if (0) {
  } elsif ($$target_inputs_ast{'klasses'}{$klass_name}) {
    $klass_type = 'klass';
  } elsif ($$target_inputs_ast{'traits'}{$klass_name}) {
    $klass_type = 'trait';
  } elsif ($$cmd_info{'opts'}{'precompile'}) {
    $klass_type = 'klass||trait';
  } else {
    my $root_cmd = &root_cmd();
    my $ast_path_var = [join '::', @{$$root_cmd{'asts'}}];
    die __FILE__, ":", __LINE__,
      ': ERROR: klass/trait "' . $klass_name . '" absent from ast(s) "' . &ct($ast_path_var) . '"' . $nl;
  }
  return $klass_type;
}
sub generics::klass_ast_from_klass_name {
  my ($klass_name, $type) = @_; # $type currently unused (should be 'klasses' or 'traits')
  my $target_inputs_ast = &target_inputs_ast();
  my $cmd_info = &root_cmd();
  my $klass_ast;

  # should use $type
  if (0) {
  } elsif ($$target_inputs_ast{'klasses'}{$klass_name}) {
    $klass_ast = $$target_inputs_ast{'klasses'}{$klass_name};
  } elsif ($$target_inputs_ast{'traits'}{$klass_name}) {
    $klass_ast = $$target_inputs_ast{'traits'}{$klass_name};
  } elsif ($$cmd_info{'opts'}{'precompile'}) {
    $klass_ast = {};
  } else {
    my $root_cmd = &root_cmd();
    my $ast_path_var = [join '::', @{$$root_cmd{'asts'} || []}];
    die __FILE__, ":", __LINE__,
      ': ERROR: klass/trait "' . $klass_name . '" absent from ast(s) "' . &ct($ast_path_var) . '"' . $nl;
  }
  return $klass_ast;
}

sub _add_indirect_klasses { # recursive
  my ($klass_names_set, $klass_name, $col) = @_;
  my $klass_ast =
    &generics::klass_ast_from_klass_name($klass_name);

  if (defined $$klass_ast{'klass'}) {
    $$klass_names_set{'klasses'}{$$klass_ast{'klass'}} = undef;

    if ('klass' ne $$klass_ast{'klass'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_ast{'klass'},
                             &colin($col));
    }
  }
  if (defined $$klass_ast{'interpose'}) {
    $$klass_names_set{'klasses'}{$$klass_ast{'interpose'}} = undef;

    if ('object' ne $$klass_ast{'interpose'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_ast{'interpose'},
                             &colin($col));
    }
  }
  if (defined $$klass_ast{'superklass'}) {
    $$klass_names_set{'klasses'}{$$klass_ast{'superklass'}} = undef;

    if ('object' ne $$klass_ast{'superklass'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_ast{'superklass'},
                             &colin($col));
    }
  }
  if (defined $$klass_ast{'traits'}) {
    foreach my $trait (@{$$klass_ast{'traits'}}) {
      $$klass_names_set{'traits'}{$trait} = undef;
      if ($klass_name ne $trait) {
        &_add_indirect_klasses($klass_names_set,
                               $trait,
                               &colin($col));
      }
    }
  }
  if (defined $$klass_ast{'requires'}) {
    foreach my $reqr (@{$$klass_ast{'requires'}}) {
      $$klass_names_set{'requires'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
        &_add_indirect_klasses($klass_names_set,
                               $reqr,
                               &colin($col));
      }
    }
  }
  if (defined $$klass_ast{'provides'}) {
    foreach my $reqr (@{$$klass_ast{'provides'}}) {
      $$klass_names_set{'provides'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
        &_add_indirect_klasses($klass_names_set,
                               $reqr,
                               &colin($col));
      }
    }
  }
}
sub add_indirect_klasses {
  my ($klass_names_set) = @_;
  foreach my $construct ('klasses', 'traits') {
    if (exists $$klass_names_set{$construct}) {
      foreach my $klass_name (keys %{$$klass_names_set{$construct}}) {
        my $col;
        &_add_indirect_klasses($klass_names_set, $klass_name, $col = '');
      }
    }
  }
}
sub generics::parse {
  my ($ast) = @_;
  my $klass_names_set = &dk_klass_names_from_file($ast);
  my $klass_name;
  my $generics;
  my $symbols = {};
  my $generics_tbl = {};
  my $big_cahuna = [];

  my $generics_used = $$ast{'generics'};
  # used in catch() rewrites
  #    $$generics_used{'instance?'} = undef; # hopefully the rhs is undef, otherwise we just lost it

  &add_indirect_klasses($klass_names_set);

  foreach my $construct ('klasses', 'traits', 'requires') {
    foreach $klass_name (keys %{$$klass_names_set{$construct}}) {
      my $klass_ast = &generics::klass_ast_from_klass_name($klass_name);

      my $data = [];
      &generics::_parse($data, $klass_ast);

      foreach my $generic (@$data) {
        if (exists $$generics_used{&ct($$generic{'name'})}) {
          &add_last($big_cahuna, $generic);
        }
      }
    }
  }
  foreach my $generic1 (@$big_cahuna) {
    if ($$generic1{'alias'}) {
      my $alias_generic = &deep_copy($generic1);
      $$alias_generic{'name'} = $$alias_generic{'alias'};
      delete $$alias_generic{'alias'};
      &add_last($big_cahuna, $alias_generic);
    }
  }
  # do the $is_va_list = 0 first, and the $is_va_list = 1 last
  # this lets us replace the former with the latter
  # (keep $is_va_list = 1 and toss $is_va_list = 0)

  foreach my $generic (@$big_cahuna) {
    if (!&is_va($generic)) {
      my $scope = [];
      my $generics_key = &func::overloadsig($generic, $scope);
      &path::remove_last($scope);
      $$generics_tbl{$generics_key} = $generic;
    }
  }
  foreach my $generic (@$big_cahuna) {
    if (&is_va($generic)) {
      my $scope = [];
      &path::add_last($scope, '$va');
      my $generics_key = &func::overloadsig($generic, $scope);
      &path::remove_last($scope);
      &path::remove_last($scope);
      $$generics_tbl{$generics_key} = $generic;
    }
  }
  my $generics_seq = [];
  #my $generic;
  while (my ($generic_key, $generic) = each(%$generics_tbl)) {
    &add_last($generics_seq, $generic);
    foreach my $arg (@{$$generic{'kw-args'} || []}) {
      &add_symbol($gbl_root_ast, $$arg{'name'});
    }
  }
  my $sorted_generics_seq = [sort method::compare @$generics_seq];
  $generics = $sorted_generics_seq;
  return ($generics, $symbols);
}
sub type_trans {
  my ($arg_type_ref) = @_;
  if (defined $arg_type_ref) {
    my $arg_type = &ct($arg_type_ref);
  }
  return $arg_type_ref;
}
sub generics::_parse { # no longer recursive
  my ($data, $klass_ast) = @_;
  foreach my $method (values %{$$klass_ast{'methods'}}) {
    my $generic = &deep_copy($method);
    $$generic{'exported?'} = 0;
    #$$generic{'inline?'} = 1;

    #if ($$generic{'alias'}) {
    #    $$generic{'name'} = $$generic{'alias'};
    #    delete $$generic{'alias'};
    #}

    #&add_last($data, $generic);
    &add_last($data, $generic);

    # not sure if we should type translate the return type
    $$generic{'return-type'} =
      &type_trans($$generic{'return-type'});

    my $args =    $$generic{'param-types'};
    my $num_args = @$args;
    my $arg_num;
    for ($arg_num = 0; $arg_num < $num_args; $arg_num++) {
      $$args[$arg_num] = &type_trans($$args[$arg_num]);
    }
  }
}
sub add_direct_constructs {
  my ($klasses, $scope, $construct_type) = @_;
  if (exists $$scope{$construct_type}) {
    foreach my $construct (@{$$scope{$construct_type}}) {
      $$klasses{$construct} = undef;
    }
  }
}
sub dk_klass_names_from_file {
  my ($file) = @_;
  my $klass_names_set = {};
  while (my ($klass_name, $klass_ast) = each(%{$$file{'klasses'}})) {
    $$klass_names_set{'klasses'}{$klass_name} = undef;
    if (defined $klass_ast) {
      my $klass = 'klass';
      if (defined $$klass_ast{'klass'}) {
        $klass = $$klass_ast{'klass'};
      }
      $$klass_names_set{'klasses'}{$klass} = undef;
      my $superklass = 'object';
      if (defined $$klass_ast{'superklass'}) {
        $superklass = $$klass_ast{'superklass'};
      }
      $$klass_names_set{'klasses'}{$superklass} = undef;

      &add_direct_constructs($klass_names_set, $klass_ast, 'traits');
    }
  }
  if (exists $$file{'traits'}) {
    while (my ($klass_name, $klass_ast) = each(%{$$file{'traits'}})) {
      $$klass_names_set{'traits'}{$klass_name} = undef;
      if (defined $klass_ast) {
        &add_direct_constructs($klass_names_set, $klass_ast, 'traits');
      }
    }
  }
  return $klass_names_set;
}
sub parse_root {
  my ($gbl_sst_cursor, $exported) = @_;
  my $depth = 0;
  $gbl_current_ast_scope = $gbl_root_ast;

  # root
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^include-for$/) {
        &include_for();
        last;
      }
      if (m/^module$/) {
        &module_decl();
        last;
      }
      if (m/^import$/) {
        &module_import_defn();
        last;
      }
      my $exported_all = 1;
      my $exported_single = 2;
      if (m/^export$/) {
        die if $exported;
        my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
        if ($next_token) {
          if ($next_token =~ /^(klass|trait)$/) {
            $exported = $exported_single;
            &match(__FILE__, __LINE__, 'export');
          } else {
            &module_export_defn();
          }
        }
        last;
      }
      if (m/^interpose$/) {
        &interpose();
        last;
      }
      if (m/^klass$/) {
        if (0 == $$gbl_sst_cursor{'current-token-index'} ||
              &sst_cursor::previous_token($gbl_sst_cursor) ne '::') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$id/) {
              &klass({'exported?' => $exported});
              if ($exported == $exported_single) {
                $exported = 0;
              }
              last;
            }
          }
        }
      }
      if (m/^trait$/) {
        my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
        if ($next_token) {
          if ($next_token =~ m/$id/) {
            &trait({'exported?' => $exported});
            if ($exported == $exported_single) {
              $exported = 0;
            }
            last;
          }
        }
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  if (exists $$gbl_root_ast{'generics'} && exists $$gbl_root_ast{'generics'}{'make'}) {
    &remove_generic($gbl_root_ast, 'make');
    &add_generic($gbl_root_ast, 'init');
  }
  $$gbl_root_ast{'should-generate-make'} = 1; # always generate make()
  return $gbl_root_ast;
}
sub add_object_methods_decls_to_klass {
  my ($klass_ast, $methods_key, $slots_methods_key) = @_;
  if (exists $$klass_ast{$slots_methods_key}) {
    while (my ($slots_method_sig, $slots_method_info) =
             each (%{$$klass_ast{$slots_methods_key}})) {
      if ($$slots_method_info{'defined?'}) {
        my $object_method_info =
          &dakota::generate::convert_to_object_method($slots_method_info);
        my $object_method_signature =
          &func::overloadsig($object_method_info, undef);

        if (($$klass_ast{'methods'}{$object_method_signature} &&
             $$klass_ast{'methods'}{$object_method_signature}{'defined?'})) {
        } else {
          $$object_method_info{'defined?'} = 0;
          $$object_method_info{'generated?'} = 1;
          #print STDERR "$object_method_signature\n";
          #print STDERR &Dumper($object_method_info);
          $$klass_ast{$methods_key}{$object_method_signature} =
            $object_method_info;
        }
      }
    }
  }
}
sub add_object_methods_decls {
  my ($ast) = @_;
  #print STDERR &Dumper($ast);

  foreach my $construct ('klasses', 'traits') {
    if (exists $$ast{$construct}) {
      while (my ($klass_name, $klass_ast) =
               each (%{$$ast{$construct}})) {
        &add_object_methods_decls_to_klass($klass_ast,
                                           'methods',
                                           'slots-methods');
      }
    }
  }
}
sub ast_from_dk_path {
  my ($arg) = @_;
  $gbl_filename = $arg;
  #print STDERR &sst::filestr($gbl_sst);
  local $_ = &filestr_from_file($gbl_filename);
  while (m/\#((0[xX][0-9a-fA-F]+|0[bB][01]+|0[0-7]+|[1-9]\d*)([uUiI](32|64|128))?)/g) {
    &add_int($gbl_root_ast, $1);
  }
  pos $_ = 0;
  while (m/\#"(.*?)"/g) {
    &add_str($gbl_root_ast, $1);
  }
  &encode_strings(\$_);
  my $parts = &encode_comments(\$_);
  &rewrite_klass_defn_with_implicit_metaklass_defn(\$_);

  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #print STDERR $_;

  pos $_ = 0;
  $_ =~ s/(\bcase\s)\s+/$1/g;
  pos $_ = 0;
  while (m/(?<!\bcase\b)\s*(#$bid)\s*$colon/g) { # kw-args use
    &add_keyword($gbl_root_ast, $1);
  }
  pos $_ = 0;
  while (m/(#$bid|#\|.*?(?<!\\)\|)/g) {
    &add_symbol($gbl_root_ast, &as_literal_symbol_interior($1));
  }
  &decode_comments(\$_, $parts);
  &decode_strings(\$_);

  $gbl_sst = &sst::make($_, $gbl_filename);

  #$gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  #&add_klasses_used($gbl_root_ast, $gbl_sst_cursor);

  $gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  &add_generics_used($gbl_root_ast, $gbl_sst_cursor);

  my $exported;
  my $result = &parse_root($gbl_sst_cursor, $exported = 0);
  &add_object_methods_decls($result);
  #print STDERR &Dumper($result);
  #print &Dumper(&kw_arg_generics());
  return $result;
}
sub start {
  my ($argv) = @_;
  # just in case ...
}
unless (caller) {
  &start(\@ARGV);
}
1;
