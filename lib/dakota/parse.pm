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

package dakota::parse;

use strict;
use warnings;

$main::seq = qr{
                 \[
                 (?:
                   (?> [^\[\]]+ )     # Non-parens without backtracking
                 |
                   (??{ $main::seq }) # Group with matching parens
                 )*
                 \]
             }x;

my $gbl_compiler;
my $gbl_header_from_symbol;
my $gbl_used;
my $objdir;
my $hh_ext;
my $cc_ext;
my $o_ext;
my $so_ext;

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
my $patterns = {
  'cc_path_from_nrt_cc_path' => '$(objdir)/%.$(cc_ext)  : $(objdir)/nrt/%.$(cc_ext)',

  'nrt_cc_path_from_dk_path' => '$(objdir)/nrt/%.$(cc_ext) : %.dk',
  'nrt_o_path_from_dk_path' =>  '$(objdir)/nrt/%.$(o_ext)  : %.dk',

  'o_path_from_cc_path' =>      '$(objdir)/%.$(o_ext)      : $(objdir)/%.$(cc_ext)',

  'ctlg_path_from_any_path' =>  '$(objdir)/%.ctlg          : %',
  'ctlg_path_from_so_path' =>   '$(objdir)/%.ctlg          : %.$(so_ext)',

  'rep_path_from_any_path' =>   '$(objdir)/%.rep           : %',
  'rep_path_from_ctlg_path' =>  '$(objdir)/%.$(so_ext).rep : $(objdir)/%.ctlg',

  'rep_path_from_so_path' =>    '$(objdir)/%.rep           : %.$(so_ext)',
  'rt_cc_path_from_any_path' => '$(objdir)/rt/%.$(cc_ext)  : %',
  'rt_cc_path_from_so_path' =>  '$(objdir)/rt/%.$(cc_ext)  : %.$(so_ext)',
};
my $expanded_patterns = &expand_tbl_values($patterns);
#print STDERR &Dumper($expanded_patterns);

BEGIN {
  my $prefix = &dk_prefix($0);
  unshift @INC, "$prefix/lib";
  use dakota::generate;
  use dakota::sst;
  use dakota::util;
  $gbl_compiler = do "$prefix/lib/dakota/compiler.json"
    or die "do $prefix/lib/dakota/compiler.json failed: $!\n";
  my $platform = do "$prefix/lib/dakota/platform.json"
    or die "do $prefix/lib/dakota/platform.json failed: $!\n";
  my ($key, $values);
  while (($key, $values) = each (%$platform)) {
    $$gbl_compiler{$key} = $values;
  }
  $gbl_header_from_symbol = do "$prefix/lib/dakota/header-from-symbol.json"
    or die "do $prefix/lib/dakota/header-from-symbol.json failed: $!\n";
  $gbl_used = do "$prefix/lib/dakota/used.json"
    or die "do $prefix/lib/dakota/used.json failed: $!\n";
  $objdir = &dakota::util::objdir();
  $hh_ext = &dakota::util::var($gbl_compiler, 'hh_ext', undef);
  $cc_ext = &dakota::util::var($gbl_compiler, 'cc_ext', undef);
  $o_ext =  &dakota::util::var($gbl_compiler, 'o_ext', undef);
  $so_ext = &dakota::util::var($gbl_compiler, 'so_ext', 'so'); # default dynamic shared object/library extension
};
#use Carp;
#$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use Cwd;
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
                 add_generic
                 add_keyword
                 add_klass_decl
                 add_str
                 add_symbol
                 add_symbol_ident
                 add_trait_decl
                 colin
                 colout
                 ctlg_path_from_any_path
                 ctlg_path_from_so_path
                 cc_path_from_nrt_cc_path
                 init_global_rep
                 kw_args_translate
                 nrt_cc_path_from_dk_path
                 nrt_o_path_from_dk_path
                 o_path_from_cc_path
                 rep_path_from_any_path
                 rep_path_from_ctlg_path
                 rep_path_from_so_path
                 rt_cc_path_from_any_path
                 rt_cc_path_from_so_path
                 str_from_cmd_info
              );
my $colon = ':'; # key/element delim only
my $kw_args_placeholders = &kw_args_placeholders();
my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();
my $h  = &dakota::util::header_file_regex();

$ENV{'DKT-DEBUG'} = 0;

sub maybe_add_exported_header_for_symbol {
  my ($symbol) = @_;
  if ($$gbl_header_from_symbol{$symbol}) {
    &add_exported_header($$gbl_header_from_symbol{$symbol});
  }
}
sub maybe_add_exported_header_for_symbol_seq {
  my ($seq) = @_;
  foreach my $symbol (@$seq) {
    &maybe_add_exported_header_for_symbol($symbol);
  }
}
sub unwrap_seq {
  my ($seq) = @_;
  $seq =~ s/\s*\n+\s*/ /gms;
  $seq =~ s/\s+/ /gs;
  return $seq;
}
sub scalar_to_file {
  my ($file, $ref) = @_;
  if (!defined $ref) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_to_file($ref)\n";
  }
  my $refstr = &Dumper($ref);
  $refstr =~ s/($main::seq)/&unwrap_seq($1)/ges; # unwrap sequences so they are only one line long (or one long line) :-)

  open(FILE, ">", $file) or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
  flock FILE, 2; # LOCK_EX
  truncate FILE, 0;
  print FILE $refstr;
  close FILE or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
}
sub kw_args_translate {
  my ($parse_tree) = @_;
  while (my ($generic, $discarded) = each(%{$$parse_tree{'generics'}})) {
    my $va_generic = $generic;

    if ($generic =~ s/^va:://) {
      delete $$parse_tree{'generics'}{$va_generic};
      $$parse_tree{'generics'}{$generic} = undef;
    }
  }

  my $constructs = [ 'klasses', 'traits' ];
  foreach my $construct (@$constructs) {
    my ($name, $scope);
    if ($$parse_tree{$construct}) {
      while (($name, $scope) = each %{$$parse_tree{$construct}}) {
        foreach my $method (values %{$$scope{'methods'}}) {
          if ('va' eq &dakota::util::first($$method{'name'})) {
            my $discarded;
            $discarded = &dakota::util::remove_first($$method{'name'}); # lose 'va'
            $discarded = &dakota::util::remove_first($$method{'name'}); # lose '::'
          }

          if ($$method{'kw-args-names'}) {
            my $kw_args_types = [];
            my $kw_args_name;        # not used
            foreach $kw_args_name (@{$$method{'kw-args-names'}}) {
              my $kw_args_type =
                &dakota::util::remove_last($$method{'parameter-types'});
              &dakota::util::add_last($kw_args_types, $kw_args_type);
            }
            &dakota::util::add_last($$method{'parameter-types'}, [ 'va-list-t' ]);
            my $kw_args_defaults = [];
            my $kw_args_default;
            if (exists  $$method{'kw-args-defaults'} &&
                defined $$method{'kw-args-defaults'}) {
              while ($kw_args_default =
                       &dakota::util::remove_last($$method{'kw-args-defaults'})) {
                my $val = "@$kw_args_default";
                &dakota::util::add_last($kw_args_defaults, $val);
              }
            } # if
            my $no_default = @$kw_args_types - @$kw_args_defaults;
            while ($no_default) {
              $no_default--;
              &dakota::util::add_last($kw_args_defaults, undef);
            }
            $$method{'keyword-types'} = [];
            my $kw_args_type;
            while (scalar @$kw_args_types) {
              my $keyword_type = {
                type =>    &dakota::util::remove_last($kw_args_types),
                default => &dakota::util::remove_last($kw_args_defaults),
                name =>    &dakota::util::remove_first($$method{'kw-args-names'}) };

              &dakota::util::add_last($$method{'keyword-types'}, $keyword_type);
            }
            delete $$method{'kw-args-names'};
            delete $$method{'kw-args-defaults'};
          } else {
            my $name = &path::string($$method{'name'});
            my $kw_args_generics = &dakota::util::kw_args_generics();
            if (exists $$kw_args_generics{$name}) {
              if (!&dakota::generate::is_va($method)) {
                &dakota::util::add_last($$method{'parameter-types'},
                                        [ 'va-list-t' ]);
                $$method{'keyword-types'} = [];
              }
            }
          }
        }
      }
    }
  }
  return $parse_tree;
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
sub _rep_merge { # recursive
  my ($root_ref, $scope) = @_;
  foreach my $name1 (sort keys %$scope) {
    if (&is_tbl($$scope{$name1})) {
      foreach my $name2 (sort keys %{$$scope{$name1}}) {
        if (!$$scope{$name1}{$name2}) {
          if (!exists $$root_ref{$name1}{$name2}) {
            $$root_ref{$name1}{$name2} = undef;
          }
        } else {
          if (!$$root_ref{$name1}{$name2}) {
            $$root_ref{$name1}{$name2} = &dakota::util::deep_copy($$scope{$name1}{$name2});
          } else {
            foreach my $name3 (sort keys %{$$scope{$name1}{$name2}}) {
              if (&is_tbl($$scope{$name1}{$name2}{$name3})) {
                &tbl_add_info($$root_ref{$name1}{$name2}{$name3},
                              $$scope{$name1}{$name2}{$name3});
              }
            }
          }
        }
      }
    }
  }
}
sub rep_merge {
  my ($argv) = @_;
  my $root_ref = {};
  foreach my $file (@$argv) {
    my $parse_tree = &dakota::util::scalar_from_file($file);
    &_rep_merge($root_ref, $parse_tree);
  }
  return $root_ref;
}

my $gbl_sst = undef;
my $gbl_sst_cursor = undef;
my $gbl_user_data = &dakota::sst::lang_user_data();

my $gbl_root = {};
my $gbl_current_scope = $gbl_root;
my $gbl_current_module = undef;
my $gbl_filename = undef;
sub init_rep_from_dk_vars {
  my ($cmd_info) = @_;
  $gbl_root = {};
  #$$gbl_root{'keywords'} = {};
  #$$gbl_root{'symbols'}  = {};

  $gbl_current_scope = $gbl_root;
  $gbl_filename = undef;
}
sub str_from_cmd_info {
  my ($cmd_info) = @_;
  #my $global_output_flags_tbl = { 'g++' => '--output', 'dakota-info' => '--output' };

  my $str = '';
  if (defined $$cmd_info{'cmd'}) {
    $str .= $$cmd_info{'cmd'};
  } else {
    $str .= '<>';
  }
  if ($$cmd_info{'cmd-major-mode-flags'}) {
    $str .= " $$cmd_info{'cmd-major-mode-flags'}";
  }
  if ($$cmd_info{'output'}) {
    $str .= " --output $$cmd_info{'output'}";
  }
  if ($$cmd_info{'output-directory'}) {
    $str .= " --output-directory $$cmd_info{'output-directory'}";
  }
  #{ $str .= " $$global_output_flags_tbl{$$cmd_info{'cmd'}} $$cmd_info{'output'}"; }
  if ($$cmd_info{'cmd-flags'}) {
    $str .= " $$cmd_info{'cmd-flags'}";
  }
  foreach my $infile (@{$$cmd_info{'reps'}}) {
    $str .= " $infile";
  }
  foreach my $infile (@{$$cmd_info{'inputs'}}) {
    $str .= " $infile";
  }
  $str =~ s|(\s)\s+|$1|g;
  return $str;
}
# found at http://linux.seindal.dk/2005/09/09/longest-common-prefix-in-perl
sub longest_common_prefix {
  my $path_prefix = shift;
  for (@_) {
    chop $path_prefix while (! /^$path_prefix/);
  }
  return $path_prefix;
}
sub rel_path_canon {
  my ($path1, $cwd) = @_;
  my $result = $path1;

  if ($path1 =~ m/\.\./g) {
    if (!$cwd) {
      $cwd = &cwd();
    }

    my $path2 = &Cwd::abs_path($path1);
    confess("ERROR: cwd=$cwd, path1=$path1, path2=$path2\n") if (!$cwd || !$path2);
    my $common_prefix = &longest_common_prefix($cwd, $path2);
    my $adj_common_prefix = $common_prefix;
    $adj_common_prefix =~ s|/[^/]+/$||g;
    $result = $path2;
    $result =~ s|^$adj_common_prefix/||;

    if ($ENV{'DKT-DEBUG'}) {
      print "$path1 = arg\n";
      print "$cwd = cwd\n";
      print "\n";
      print "$path1 = $path1\n";
      print "$result = $path1\n";
      print "$result = result\n";
    }
  }
  return $result;
}
sub cc_path_from_nrt_cc_path {
  my ($path) = @_;
  return &out_path_from_in_path('cc_path_from_nrt_cc_path', $path);
}
sub ctlg_path_from_so_path {
  my ($path) = @_;
  return &out_path_from_in_path('ctlg_path_from_so_path', $path);
}
sub ctlg_path_from_any_path {
  my ($path) = @_;
  return &out_path_from_in_path('ctlg_path_from_any_path', $path);
}
sub nrt_cc_path_from_dk_path {
  my ($path) = @_;
  return &out_path_from_in_path('nrt_cc_path_from_dk_path', $path);
}
sub nrt_o_path_from_dk_path {
  my ($path) = @_;
  return &out_path_from_in_path('nrt_o_path_from_dk_path', $path);
}
sub o_path_from_cc_path {
  my ($path) = @_;
  return &out_path_from_in_path('o_path_from_cc_path', $path);
}
sub rep_path_from_any_path {
  my ($path) = @_;
  return &out_path_from_in_path('rep_path_from_any_path', $path);
}
sub rep_path_from_ctlg_path {
  my ($path) = @_;
  return &out_path_from_in_path('rep_path_from_ctlg_path', $path);
}
sub rep_path_from_so_path {
  my ($path) = @_;
  return &out_path_from_in_path('rep_path_from_so_path', $path);
}
sub rt_cc_path_from_any_path {
  my ($path) = @_;
  return &out_path_from_in_path('rt_cc_path_from_any_path', $path);
}
sub rt_cc_path_from_so_path {
  my ($path) = @_;
  return &out_path_from_in_path('rt_cc_path_from_so_path', $path);
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
  $str =~ s/(\$\w+)/$1/eeg;
  return $str;
}
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
sub add_symbol_ident {
  my ($file, $ident) = @_;
  if ($ident !~ m/^#/) {
    $ident = '#' . $ident;
  }
  $$file{'symbols'}{$ident} = undef;
}
sub add_symbol {
  my ($file, $symbol) = @_;
  my $ident = &path::string($symbol);
  &add_symbol_ident($file, $ident);
}
sub add_system_include {
  my ($file, $system_include) = @_;
  $$file{'includes'}{$system_include} = undef;
}
sub add_type {
  my ($seq) = @_;
  &maybe_add_exported_header_for_symbol_seq($seq);
}
sub add_hash {
  my ($file, $str) = @_;
  my $ident = &path::string([$str]);
  $$file{'hashes'}{$ident} = undef;
}
sub add_keyword {
  my ($file, $keyword) = @_;
  my $ident = &path::string([$keyword]);
  if ($ident !~ m/^#/) {
    $ident = '#' . $ident;
  }
  $$file{'keywords'}{$ident} = undef;
  &add_symbol($file, [$keyword]);
}
sub add_str {
  my ($file, $str) = @_;
  &add_symbol($file, [$str]);
  $$file{'literal-strs'}{$str} = undef;
}
sub add_int {
  my ($file, $val) = @_;
  $$file{'literal-ints'}{$val} = undef;
  &add_symbol($file, [$val]);
}
sub token_seq::simple_seq {
  my ($tokens) = @_;
  my $seq = [];
  my $tkn;
  for $tkn (@$tokens) {
    &dakota::util::add_last($seq, $$tkn{'str'});
  }
  return $seq;
}
sub warning {
  my ($file, $line, $token_index) = @_;
  printf STDERR "%s:%i: warning/error\n",
    $file,
    $line;

  printf STDERR "%s:%i: did not expect \'%s\'\n",
    $gbl_filename,
    $$gbl_sst{'tokens'}[$token_index]{'line'},
    &sst::at($gbl_sst, $token_index);
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
sub add_exported_header {
  my ($tkn) = @_;
  $$gbl_root{'exported-headers'}{$tkn} = undef;
}
sub header {
  my $tkn = &match_any();
  &match(__FILE__, __LINE__, ';');
  $$gbl_root{'headers'}{$tkn} = undef;
}
sub exported_header {
  my $tkn = &match_any();
  &match(__FILE__, __LINE__, ';');
  &add_exported_header($tkn);
}
sub trait {
  my ($args) = @_;
  my ($body, $seq) = &dkdecl('trait');

  if (&sst_cursor::current_token($gbl_sst_cursor) eq ';') {
    $$gbl_root{'traits'}{$body} = undef;
    &match(__FILE__, __LINE__, ';');

    if ($$args{'exported?'}) {
      $$gbl_root{'exported-trait-decls'}{$body} = {};
      $$gbl_current_scope{'exported-trait-decls'} = &dakota::util::deep_copy($$gbl_root{'exported-trait-decls'});
    }
    return $body;
  }
  &match(__FILE__, __LINE__, '{');
  my $braces = 1;
  my $previous_scope = $gbl_current_scope;
  my $construct_name = &path::string($seq);

  if (!defined $$gbl_current_scope{'traits'}{$construct_name}) {
    $$gbl_current_scope{'traits'}{$construct_name}{'defined?'} = 1;
  }
  if ($$args{'exported?'}) {
    $$gbl_current_scope{'traits'}{$construct_name}{'exported?'} = 1;
  }
  $gbl_current_scope = $$gbl_current_scope{'traits'}{$construct_name};
  $$gbl_current_scope{'module'} = $gbl_current_module;
  $$gbl_current_scope{'file'} = $$gbl_sst_cursor{'sst'}{'file'};

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
          if (m/^method$/) {
            $$gbl_root{'traits'}{$construct_name}{'exported?'} = 1; # export trait if any method is exported
            $$gbl_root{'traits'}{$construct_name}{'behavior-exported?'} = 1;
            &method( {'exported?' => 1 });
            last;
          }
        }
      }
      if (m/^method$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '{' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '}' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &method({ 'exported?' => 0 });
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!exists $$gbl_current_scope{'traits'}) {
          $$gbl_current_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
          &dakota::util::add_last($$gbl_current_scope{'traits'}, $trait);
        }
        last;
      }
      if (m/^require$/) {
        my ($body, $seq) = &dkdecl('require');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'requires'}) {
          $$gbl_current_scope{'requires'} = [];
        }
        &dakota::util::add_last($$gbl_current_scope{'requires'}, &path::string($seq));
        last;
      }
      if (m/^provide$/) {
        my ($body, $seq) = &dkdecl('provide');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'provides'}) {
          $$gbl_current_scope{'provides'} = [];
        }
        &dakota::util::add_last($$gbl_current_scope{'provides'}, &path::string($seq));
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
          $gbl_current_scope = $previous_scope;
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
      &add_symbol($gbl_root, [ $name ]);
      my $slot_info = { 'name' => $name,
                        'type' => &arg::type($type) };
      if (scalar @$expr) {
        $$slot_info{'expr'} = join(' ', @$expr);
      }
      &add_last($seq, $slot_info);
      &maybe_add_exported_header_for_symbol_seq($type);
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
      &add_symbol($gbl_root, [ $name ]);
      if (scalar @$expr) {
        if ('=' ne &remove_first($expr)) {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        $$slot_info{'expr'} = join(' ', @$expr);
      }
      &add_last($seq, $slot_info);
      &maybe_add_exported_header_for_symbol_seq($expr);
      $expr = [];
    }
  }
  if (scalar @$expr) {
    my $name = &remove_first($expr);
    my $slot_info = { 'name' => $name };
    &add_symbol($gbl_root, [ $name ]);
    if (scalar @$expr) {
      if ('=' ne &remove_first($expr)) {
        die __FILE__, ":", __LINE__, ": error:\n";
      }
      $$slot_info{'expr'} = join(' ', @$expr);
    }
    &add_last($seq, $slot_info);
    &maybe_add_exported_header_for_symbol_seq($expr);
  }
  #print 'enum_seq: ' . &Dumper($seq);
  return;
}
sub errdump {
  my ($ref) = @_;
  print STDERR Dumper $ref;
}
sub slots {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'slots');
  if ($$args{'exported?'}) {
    $$gbl_current_scope{'slots'}{'exported?'} = 1;
  }
  # slots are always in same module as klass
  $$gbl_current_scope{'slots'}{'module'} = $$gbl_current_scope{'module'};

  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor) &&
         '{' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &dakota::util::add_last($type, $tkn);
  }
  my $cat = 'struct';
  if (@$type && 3 == @$type) {
    if ('enum' eq &dakota::util::first($type)) {
      my $enum_base = &dakota::util::remove_last($type);
      my $tkn =    &dakota::util::remove_last($type);
      die if ':' ne $tkn; # not key/element delim
      $$gbl_current_scope{'slots'}{'enum-base'} = $enum_base;
      #print STDERR &Dumper($$gbl_current_scope{'slots'});
    }
  }
  if (@$type && 1 == @$type) {
    if ('struct' eq &dakota::util::first($type) ||
        'union' eq  &dakota::util::first($type) ||
        'enum' eq   &dakota::util::first($type)) {
      if ('enum' eq &dakota::util::first($type)) {
        &add_symbol($gbl_root, ['enum-info']);
        &add_symbol($gbl_root, ['const-info']);

        &add_klass_decl($gbl_root, 'enum-info');
        &add_klass_decl($gbl_root, 'named-enum-info');
        &add_klass_decl($gbl_root, 'const-info');
      }
      $cat = &dakota::util::remove_first($type);
      $$gbl_current_scope{'slots'}{'cat'} = $cat;
    }
  }
  if (@$type) {
    &add_type($type);
    $$gbl_current_scope{'slots'}{'type'} = &arg::type($type);
  } else {
    $$gbl_current_scope{'slots'}{'cat'} = $cat;
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
      $$gbl_current_scope{'slots'}{'info'} = [];
      $$gbl_current_scope{'slots'}{'file'} = $$gbl_sst_cursor{'sst'}{'file'};
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      if ($open_curley_index + 1 != $close_curley_index) {
        my $slots_defs = &sst::token_seq($gbl_sst, $open_curley_index + 1, $close_curley_index - 1);
        if ('enum' eq $cat) {
          &enum_seq($slots_defs, $$gbl_current_scope{'slots'}{'info'});
        } else {
          &slots_seq($slots_defs, $$gbl_current_scope{'slots'}{'info'});
        }
      }
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      &add_symbol($gbl_root, ['size']);
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
  if (!exists $$gbl_current_scope{'const'}) {
    $$gbl_current_scope{'const'} = [];
  }
  my $const = {};
  if ($$args{'exported?'}) {
    $$const{'exported?'} = 1;
  }
  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &dakota::util::add_last($type, $tkn);
  }
  my $rhs = [];
  if ("@$type" =~ m/=/) {
    while ('=' ne &dakota::util::last($type)) {
      &dakota::util::add_first($rhs, &dakota::util::remove_last($type));
    }
    &dakota::util::remove_last($type); # '='
  }
  my $name = &dakota::util::remove_last($type);
  &add_symbol($gbl_root, [ $name ]); # const var name
  if (@$type) {
    $$const{'type'} = &arg::type($type);
    $$const{'name'} = $name;
    $$const{'rhs'} = $rhs;
  }
  if (';' eq &sst_cursor::current_token($gbl_sst_cursor)) {
    &match(__FILE__, __LINE__, ';');
    &dakota::util::add_last($$gbl_current_scope{'const'}, $const);
    return;
  }
}
sub enum {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'enum');
  if (!exists $$gbl_current_scope{'enum'}) {
    $$gbl_current_scope{'enum'} = [];
  }
  my $enum = {};
  if ($$args{'exported?'}) {
    $$enum{'exported?'} = 1;
  }
  my $type = [];
  while (';' ne &sst_cursor::current_token($gbl_sst_cursor) &&
         '{' ne &sst_cursor::current_token($gbl_sst_cursor)) {
    my $tkn = &match_any();
    &dakota::util::add_last($type, $tkn);
  }
  if (@$type) {
    &add_type($type);
    $$enum{'type'} = &arg::type($type);
  }
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      &dakota::util::add_last($$gbl_current_scope{'enum'}, $enum);
      return;
    }
    if (m/^\{$/) {
      if (@$type) {
        $$enum{'type'} = $type;
      }
      $$enum{'info'} = [];
      my ($open_curley_index, $close_curley_index) =
        &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
      if ($open_curley_index + 1 != $close_curley_index) {
        my $enum_defs = &sst::token_seq($gbl_sst,
                                        $open_curley_index + 1,
                                        $close_curley_index - 1);
        &enum_seq($enum_defs, $$enum{'info'});
      }
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      &add_symbol($gbl_root, ['enum-info']);
      &add_symbol($gbl_root, ['const-info']);

      &add_klass_decl($gbl_root, 'enum-info');
      &add_klass_decl($gbl_root, 'named-enum-info');
      &add_klass_decl($gbl_root, 'const-info');
      &dakota::util::add_last($$gbl_current_scope{'enum'}, $enum);
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
  &match(__FILE__, __LINE__, 'object-t');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root, ['initialize']);
      $$gbl_current_scope{'has-initialize'} = 1;
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
  &match(__FILE__, __LINE__, 'object-t');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root, ['finalize']);
      $$gbl_current_scope{'has-finalize'} = 1;
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
sub export {
  &match(__FILE__, __LINE__, 'export');

  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^klass$/) {
      &klass({ 'exported?' => 1 });
      last;
    }
    if (m/^trait$/) {
      &trait({ 'exported?' => 1 });
      last;
    }

    if (m/^"$h+"$/) {
      &exported_header();
      last;
    }
    if (m/^<$h+>$/) {
      &exported_header();
      last;
    }

    $$gbl_sst_cursor{'current-token-index'}++;
  }
}
sub interpose {
  my ($args) = @_;
  my $seq = &dkdecl_list('interpose');
  my $first = &dakota::util::remove_first($seq);
  if ($$gbl_root{'interposers'}{$first}) {
    die __FILE__, ":", __LINE__, ": error:\n";
  }
  if ($$gbl_root{'interposers-unordered'}{$first}) {
    # check for sameness here
    delete $$gbl_root{'interposers-unordered'}{$first};
  }
  $$gbl_root{'interposers'}{$first} = $seq;
}
# this works for methods because zero or one params are allowed, so comma is not seen in a a param list
sub match_qual_ident {
  my ($file, $line) = @_;
  my $seq = [];
  while (&sst_cursor::current_token($gbl_sst_cursor) ne ',' &&
         &sst_cursor::current_token($gbl_sst_cursor) ne ';') {
    my $token = &match_any();
    &dakota::util::add_last($seq, $token);
  }
  if (0 == @$seq) {
    $seq = undef;
  }
  return $seq;
}
sub module_export {
  my ($module_name) = @_;
  &match(__FILE__, __LINE__, 'export');
  my $tbl = {};
  while (1) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (0) {
      } elsif (m/^;$/) {
        &match(__FILE__, __LINE__, ';');
        $$gbl_root{'modules'}{$module_name}{'export'} = $tbl;
        return;
      } elsif (m/^,$/) {
        &match(__FILE__, __LINE__, ',');
        my $seq = &match_qual_ident(__FILE__, __LINE__);
        if (!$seq) {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        $$tbl{"@$seq"} = $seq;
      } else {
        my $seq = &match_qual_ident(__FILE__, __LINE__);
        if (!$seq) {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        $$tbl{"@$seq"} = $seq;
      }
    }
  }
}
sub module_statement {
  &match(__FILE__, __LINE__, 'module');
  my $module_name = &match_re(__FILE__, __LINE__, $id);
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (0) {
    } elsif (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      $gbl_current_module = $module_name;
      return;
    } elsif (m/^\{$/) {
      &match(__FILE__, __LINE__, '{');
      for (&sst_cursor::current_token($gbl_sst_cursor)) {
        if (0) {
        } elsif (m/^export$/) {
          &module_export($module_name);
        } else {
          print STDERR "TOKEN: " . &sst_cursor::current_token($gbl_sst_cursor) . "\n";
          die __FILE__, ":", __LINE__, ": error:\n";
        }
      }
      &match(__FILE__, __LINE__, '}');
    } else {
      print STDERR "TOKEN: " . &sst_cursor::current_token($gbl_sst_cursor) . "\n";
      die __FILE__, ":", __LINE__, ": error:\n";
    }
  }
  #print STDERR &Dumper($$gbl_root{'modules'});
}
sub klass {
  my ($args) = @_;
  my ($body, $seq) = &dkdecl('klass');

  if (&sst_cursor::current_token($gbl_sst_cursor) eq ';') {
    $$gbl_root{'klasses'}{$body} = undef;
    &match(__FILE__, __LINE__, ';');

    if ($$args{'exported?'}) {
      $$gbl_root{'exported-klass-decls'}{$body} = {};
      $$gbl_current_scope{'exported-klass-decls'} =
        &dakota::util::deep_copy($$gbl_root{'exported-klass-decls'});
    }
    return $body;
  }
  &match(__FILE__, __LINE__, '{');
  my $braces = 1;
  my $previous_scope = $gbl_current_scope;
  my $construct_name = &path::string($seq);

  if (!defined $$gbl_current_scope{'klasses'}{$construct_name}) {
    $$gbl_current_scope{'klasses'}{$construct_name}{'defined?'} = 1;
  }
  if ($$args{'exported?'}) {
    $$gbl_current_scope{'klasses'}{$construct_name}{'exported?'} = 1;
  }
  $gbl_current_scope = $$gbl_current_scope{'klasses'}{$construct_name};
  $$gbl_current_scope{'module'} = $gbl_current_module;
  $$gbl_current_scope{'file'} = $$gbl_sst_cursor{'sst'}{'file'};

  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^export$/) {
        &match(__FILE__, __LINE__, 'export');
        for (&sst_cursor::current_token($gbl_sst_cursor)) {
          if (m/^const$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either enums or slots or methods are exported
              &const({ 'exported?' => 1 });
              last;
            }
          }
          if (m/^enum$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either enums or slots or methods are exported
              &enum({ 'exported?' => 1 });
              last;
            }
          }
          if (m/^slots$/) {
            if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
              $$gbl_root{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either slots or methods are exported
              &slots({ 'exported?' => 1 });
              last;
            }
          }
          if (m/^method$/) {
            $$gbl_root{'klasses'}{$construct_name}{'exported?'} = 1; # export klass if either slots or methods are exported
            $$gbl_root{'klasses'}{$construct_name}{'behavior-exported?'} = 1;
            &method({ 'exported?' => 1 });
            last;
          }
        }
        last;
      }
      if (m/^slots$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) || '{' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &slots({ 'exported?' => 0 });
          last;
        }
      }
      if (m/^initialize$/) {
        &initialize();
        last;
      }
      if (m/^finalize$/) {
        &finalize();
        last;
      }
      if (m/^method$/) {
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '{' eq &sst_cursor::previous_token($gbl_sst_cursor) ||
            '}' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &method({ 'exported?' => 0 });
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!exists $$gbl_current_scope{'traits'}) {
          $$gbl_current_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
          &add_trait_decl($gbl_root, $trait);
          &dakota::util::add_last($$gbl_current_scope{'traits'}, $trait);
        }
        last;
      }
      if (m/^require$/) {
        my ($body, $seq) = &dkdecl('require');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'requires'}) {
          $$gbl_current_scope{'requires'} = [];
        }
        my $path = &path::string($seq);
        &dakota::util::add_last($$gbl_current_scope{'requires'}, $path);
        &add_klass_decl($gbl_root, $path);
        last;
      }
      if (m/^provide$/) {
        my ($body, $seq) = &dkdecl('provide');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'provides'}) {
          $$gbl_current_scope{'provides'} = [];
        }
        my $path = &path::string($seq);
        &dakota::util::add_last($$gbl_current_scope{'provides'}, $path);
        &add_klass_decl($gbl_root, $path);
        last;
      }
      if (m/^interpose$/) {
        my ($body, $seq) = &dkdecl('interpose');
        &match(__FILE__, __LINE__, ';');
        my $name = &path::string($seq);
        $$gbl_current_scope{'interpose'} = $name;
        &add_klass_decl($gbl_root, $name);

        if (!$$gbl_root{'interposers'}{$name} &&
            !$$gbl_root{'interposers-unordered'}{$name}) {
          $$gbl_root{'interposers'}{$name} = [];
          &dakota::util::add_last($$gbl_root{'interposers'}{$name}, $construct_name);
        } elsif ($$gbl_root{'interposers'}{$name}) {
          $$gbl_root{'interposers-unordered'}{$name} = $$gbl_root{'interposers'}{$name};
          delete $$gbl_root{'interposers'}{$name};
          &dakota::util::add_last($$gbl_root{'interposers-unordered'}{$name}, $construct_name);
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
              my $path = &path::string($seq);
              $$gbl_current_scope{'superklass'} = $path;
              &add_klass_decl($gbl_root, $path);
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
              my $path = &path::string($seq);
              $$gbl_current_scope{'klass'} = $path;
              &add_klass_decl($gbl_root, $path);
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
          $gbl_current_scope = $previous_scope;
          return &path::string($seq);
        }
        last;
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  return &path::string($seq);
}
sub dkdecl {
  my ($tkn) = @_;
  &match(__FILE__, __LINE__, $tkn);
  my $parts = [];

  while (&sst_cursor::current_token($gbl_sst_cursor) ne ';' &&
         &sst_cursor::current_token($gbl_sst_cursor) ne '{') {
    &dakota::util::add_last($parts, &sst_cursor::current_token($gbl_sst_cursor));
    $$gbl_sst_cursor{'current-token-index'}++;
  }

  #    if ('::' ne $parts[0])
  #    {
  #        &dakota::util::add_first($parts, '::');
  #    }
  my $body = &path::string($parts);
  return ($body, $parts);
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
      &dakota::util::add_last($parts, $body);
      $body = '';
    }
    $$gbl_sst_cursor{'current-token-index'}++;
  }
  &dakota::util::add_last($parts, $body);
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
    &dakota::util::remove_last($type);
  }
  foreach my $token (@$type) {
    &add_type([$token]);
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
      &dakota::util::add_last($$result[$i], $tkn);
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
sub kw_args_offsets {
  my ($seq, $gbl_token) = @_;
  my $result;
  my $i;
  for ($i = 0; $i < @$seq; $i++) {
    if ($colon eq $$seq[$i]) {
      $result = $i;
    }
  }
  return ( $result );
}
sub parameter_list {
  my ($parameter_types) = @_;
  #print STDERR Dumper $parameter_types;
  my $params = [];
  my $parameter_token;
  my $len = @$parameter_types;
  my $i = 0;
  while ($i < $len) {
    my $parameter_n = [];
    my $opens = 0;
    while ($i < $len) {
      for ($$parameter_types[$i]) {
        if (m/^\,$/) {
          if ($opens) {
            &dakota::util::add_last($parameter_n, $$parameter_types[$i]);
            $i++;
          } else {
            $i++;
            &dakota::util::add_last($params, $parameter_n);
            $parameter_n = [];
            next;
          }
        } elsif (m/^\{|\($/) {
          $opens++;
          &dakota::util::add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        } elsif (m/^\)|\}$/) {
          $opens--;
          &dakota::util::add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        } else {
          &dakota::util::add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        }
      }
    }
    $i++;
    &dakota::util::add_last($params, $parameter_n);
  }
  #print STDERR Dumper $params;
  my $types = [];
  my $kw_args_names = [];
  my $kw_args_defaults = [];
  foreach my $type (@$params) {
    if (':' eq $$type[-1]) {
      push @$type, split('', $$kw_args_placeholders{'nodefault'});
    }
    my ($colon_offset) = &kw_args_offsets($type);

    if ($colon_offset) {
      my $kw_args_name = $colon_offset - 1;
      my $kw_args_default = [splice(@$type, $colon_offset)];
      my $colon_tkn = &dakota::util::remove_first($kw_args_default);
      my $kw_arg_nodefault_placeholder = $$kw_args_placeholders{'nodefault'};
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
          &dakota::util::add_last($kw_args_defaults, $kw_args_default);
        }
      } else {
        &dakota::util::add_last($kw_args_defaults, $kw_args_default);
      }
      my $kw_args_name_seq = [splice(@$type, $kw_args_name)];
      #print STDERR Dumper $kw_args_name_seq;
      #print STDERR Dumper $type;
      &dakota::util::add_last($kw_args_names, &dakota::util::remove_last($kw_args_name_seq));
    } else {
      my $ident = &dakota::util::remove_last($type);
      if ($ident =~ m/\-t$/) {
        &dakota::util::add_last($type, $ident);
      } elsif (!($ident =~ m/$id/)) {
        &dakota::util::add_last($type, $ident);
      }
    }
    &dakota::util::add_last($types, $type);
  }

  if (0 == @$kw_args_names) {
    $kw_args_names = undef;
  }

  if (0 == @$kw_args_defaults) {
    $kw_args_defaults = undef;
  }
  return ($types, $kw_args_names, $kw_args_defaults);
}
sub add_klasses_used {
  my ($scope, $gbl_sst_cursor) = @_;
  my $seqs = $$gbl_used{'used-klasses'};
  my $size = &sst_cursor::size($gbl_sst_cursor);
  for (my $i = 0; $i < $size - 2; $i++) {
    my $first_index = $$gbl_sst_cursor{'first-token-index'} ||= 0;
    my $last_index = $$gbl_sst_cursor{'last-token-index'} ||= undef;
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
            print "FILE: " . $$gbl_sst_cursor{'file'} . "\n";
          }
          print "RANGE: " . &Dumper($range) . ", MATCHES: " . &Dumper($matches) . ", NAME: " . $name . "\n";
          $Data::Dumper::Indent = $prev_indent;
        }
        &add_klass_decl($gbl_root, $name);
      }
    }
  }
}
sub add_all_generics_used {
  my ($gbl_sst_cursor, $scope, $args) = @_;
  my ($range, $matches) = &sst_cursor::match_pattern_seq($gbl_sst_cursor, $$args{'pattern'});
  if ($range) {
    my $name = &sst_cursor::str($gbl_sst_cursor, $$args{'range'});
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
    my $first_index = $$gbl_sst_cursor{'first-token-index'} ||= 0;
    my $last_index = $$gbl_sst_cursor{'last-token-index'} ||= undef;
    my $new_sst_cursor = &sst_cursor::make($$gbl_sst_cursor{'sst'}, $first_index + $i, $last_index);

    foreach my $seq (@$seqs) {
      &add_all_generics_used($new_sst_cursor, $scope, $seq);
    }
  }
  #print STDERR &sst::filestr($$gbl_sst_cursor{'sst'});
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
  if (&sst_cursor::current_token($gbl_sst_cursor) eq '[') {
    my ($open_bracket_index, $close_bracket_index)
      = &sst_cursor::balenced($gbl_sst_cursor, $gbl_user_data);
    &match(__FILE__, __LINE__, '[');
    &match(__FILE__, __LINE__, '[');
    my $attr = &match_re(__FILE__, __LINE__, $id);
    &match(__FILE__, __LINE__, '(');
    my $attr_arg = &match_any(__FILE__, __LINE__);
    &match(__FILE__, __LINE__, ')');
    &match(__FILE__, __LINE__, ']');
    &match(__FILE__, __LINE__, ']');

    if (0) {
    } elsif ('alias' eq $attr) {
      $$method{'alias'} = [ $attr_arg ];
    } elsif ('format-printf' eq $attr || 'format-va-printf' eq $attr) {
      if (!exists $$method{'attributes'}) {
        $$method{'attributes'} = [];
      }
      &dakota::util::add_last($$method{'attributes'}, $attr);
    }
  }
  my $name = [];
  push @$name, &match_re(__FILE__, __LINE__, '[\w-]+');
  if ('va' eq $$name[0]) {
    $$method{'is-va'} = 1;
    push @$name, &match(__FILE__, __LINE__, '::');
    push @$name, &match_re(__FILE__, __LINE__, '[\w-]+');
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
    push @$realname, &match_re(__FILE__, __LINE__, '[\w-]+');
    if ($$method{'is-va'}) {
      push @$realname, &match(__FILE__, __LINE__, '::');
      push @$realname, &match_re(__FILE__, __LINE__, '[\w-]+');
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
    ###&add_generic($gbl_root, "@{$$method{'name'}}");
    return;
  } else {
    $$method{'name'} = $name;
    &add_generic($gbl_root, "@{$$method{'name'}}");
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
  my $parameter_types = &sst::token_seq($gbl_sst,
                                        $open_paren_index + 1,
                                        $close_paren_index - 1);
  $parameter_types = &token_seq::simple_seq($parameter_types);
  my ($kw_args_parameter_types, $kw_args_names, $kw_args_defaults) =
    &parameter_list($parameter_types);
  $$method{'parameter-types'} = $kw_args_parameter_types;

  if ($kw_args_names) {
    my $method_name = "@{$$method{'name'}}";
    &dakota::util::kw_args_generics_add($method_name);
    if ('init' eq $method_name) {
      foreach my $kw_arg_name (@$kw_args_names) {
        if ('slots' eq $kw_arg_name) {
          if (1 == @$kw_args_names) {
            # only one kw-arg and its slots (does not matter aggregate or not)
            $$gbl_current_scope{'init-supports-kw-slots?'} = 1;
          } elsif ($$gbl_current_scope{'slots'} && $$gbl_current_scope{'slots'}{'type'}) {
            # not an aggregate
            $$gbl_current_scope{'init-supports-kw-slots?'} = 1;
          } else {
            my $kw_arg_names_list = join(', #', @$kw_args_names);
            print STDERR "warning: slots is an aggregate and init(#$kw_arg_names_list) supports more than just #slots.\n";
          }
        }
      }
    }
  }
  if ($kw_args_names) {
    $$method{'kw-args-names'} = $kw_args_names;
  }
  if ($kw_args_defaults) {
    $$method{'kw-args-defaults'} = $kw_args_defaults;
  }
  $$gbl_sst_cursor{'current-token-index'} = $close_paren_index + 1;

  #print STDERR &Dumper($method);
  &match(__FILE__, __LINE__, '->'); # this syntax is similiar to how Lambda functions are specified in C++11

  ### RETURN-TYPE
  my $return_type = [];
  while (&sst::at($$gbl_sst_cursor{'sst'},
                  $$gbl_sst_cursor{'current-token-index'}) !~ m/^(\;|\{)$/) {
    push @$return_type, &match_any();
  }
  if ('void' eq &path::string($return_type)) {
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
  my $signature = &function::overloadsig($method, undef);

  if (0) {
  } elsif (&dakota::generate::is_slots($method) &&
             &dakota::generate::is_va($method)) { # 11
    if (!defined $$gbl_current_scope{'slots-methods'}) {
      $$gbl_current_scope{'slots-methods'} = {};
    }
    $$gbl_current_scope{'slots-methods'}{$signature} = $method;
  } elsif (&dakota::generate::is_slots($method) &&
             !&dakota::generate::is_va($method)) { # 10
    if (!defined $$gbl_current_scope{'slots-methods'}) {
      $$gbl_current_scope{'slots-methods'} = {};
    }
    $$gbl_current_scope{'slots-methods'}{$signature} = $method;
  } elsif (!&dakota::generate::is_slots($method) &&
             &dakota::generate::is_va($method)) { # 01
    if (!defined $$gbl_current_scope{'methods'}) {
      $$gbl_current_scope{'methods'} = {};
    }
    $$gbl_current_scope{'methods'}{$signature} = $method;
  } elsif (!&dakota::generate::is_slots($method) &&
             !&dakota::generate::is_va($method)) { # 00
    if (!defined $$gbl_current_scope{'methods'}) {
      $$gbl_current_scope{'methods'} = {};
    }
    $$gbl_current_scope{'methods'}{$signature} = $method;
  }
  return;
}
my $global_root_cmd;
my $global_rep;
sub init_cc_from_dk_vars {
  my ($cmd_info) = @_;
  $global_root_cmd = $cmd_info;
}
sub generics::klass_type_from_klass_name {
  my ($klass_name) = @_;
  my $klass_type;

  if (0) {
  } elsif ($$global_rep{'klasses'}{$klass_name}) {
    $klass_type = 'klass';
  } elsif ($$global_rep{'traits'}{$klass_name}) {
    $klass_type = 'trait';
  } elsif ($ENV{'DKT_PRECOMPILE'}) {
    $klass_type = 'klass||trait';
  } else {
    my $rep_path_var = [join '::', @{$$global_root_cmd{'reps'}}];
    die __FILE__, ":", __LINE__,
      ": ERROR: klass/trait \"$klass_name\" absent from rep(s) \"@$rep_path_var\"\n";
  }
  return $klass_type;
}
sub generics::klass_scope_from_klass_name {
  my ($klass_name, $type) = @_; # $type currently unused (should be 'klasses' or 'traits')
  my $klass_scope;

  # should use $type
  if (0) {
  } elsif ($$global_rep{'klasses'}{$klass_name}) {
    $klass_scope = $$global_rep{'klasses'}{$klass_name};
  } elsif ($$global_rep{'traits'}{$klass_name}) {
    $klass_scope = $$global_rep{'traits'}{$klass_name};
  } elsif ($ENV{'DKT_PRECOMPILE'}) {
    $klass_scope = {};
  } else {
    my $rep_path_var = [join '::', @{$$global_root_cmd{'reps'} ||= []}];
    die __FILE__, ":", __LINE__, ": ERROR: klass/trait \"$klass_name\" absent from rep(s) \"@$rep_path_var\"\n";
  }
  return $klass_scope;
}

sub _add_indirect_klasses { # recursive
  my ($klass_names_set, $klass_name, $col) = @_;
  my $klass_scope =
    &generics::klass_scope_from_klass_name($klass_name);

  if (defined $$klass_scope{'klass'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'klass'}} = undef;

    if ('klass' ne $$klass_scope{'klass'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_scope{'klass'},
                             &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'interpose'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'interpose'}} = undef;

    if ('object' ne $$klass_scope{'interpose'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_scope{'interpose'},
                             &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'superklass'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'superklass'}} = undef;

    if ('object' ne $$klass_scope{'superklass'}) {
      &_add_indirect_klasses($klass_names_set,
                             $$klass_scope{'superklass'},
                             &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'traits'}) {
    foreach my $trait (@{$$klass_scope{'traits'}}) {
      $$klass_names_set{'traits'}{$trait} = undef;
      if ($klass_name ne $trait) {
        &_add_indirect_klasses($klass_names_set,
                               $trait,
                               &dakota::generate::colin($col));
      }
    }
  }
  if (defined $$klass_scope{'requires'}) {
    foreach my $reqr (@{$$klass_scope{'requires'}}) {
      $$klass_names_set{'requires'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
        &_add_indirect_klasses($klass_names_set,
                               $reqr,
                               &dakota::generate::colin($col));
      }
    }
  }
  if (defined $$klass_scope{'provides'}) {
    foreach my $reqr (@{$$klass_scope{'provides'}}) {
      $$klass_names_set{'provides'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
        &_add_indirect_klasses($klass_names_set,
                               $reqr,
                               &dakota::generate::colin($col));
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
  my ($parse_tree) = @_;
  my $klass_names_set = &dk_klass_names_from_file($parse_tree);
  my $klass_name;
  my $generics;
  my $symbols = {};
  my $generics_tbl = {};
  my $big_cahuna = [];

  my $generics_used = $$parse_tree{'generics'};
  # used in catch() rewrites
  #    $$generics_used{'instance?'} = undef; # hopefully the rhs is undef, otherwise we just lost it

  &add_indirect_klasses($klass_names_set);

  foreach my $construct ('klasses', 'traits', 'requires') {
    foreach $klass_name (keys %{$$klass_names_set{$construct}}) {
      my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);

      my $data = [];
      &generics::_parse($data, $klass_scope);

      foreach my $generic (@$data) {
        if (exists $$generics_used{"@{$$generic{'name'}}"}) {
          &dakota::util::add_last($big_cahuna, $generic);
        }
      }
    }
  }
  foreach my $generic1 (@$big_cahuna) {
    if ($$generic1{'alias'}) {
      my $alias_generic = &dakota::util::deep_copy($generic1);
      $$alias_generic{'name'} = $$alias_generic{'alias'};
      delete $$alias_generic{'alias'};
      &dakota::util::add_last($big_cahuna, $alias_generic);
    }
  }
  # do the $is_va_list = 0 first, and the $is_va_list = 1 last
  # this lets us replace the former with the latter
  # (keep $is_va_list = 1 and toss $is_va_list = 0)

  foreach my $generic (@$big_cahuna) {
    if (!&dakota::generate::is_va($generic)) {
      my $scope = [];
      &path::add_last($scope, 'dk');
      my $generics_key = &function::overloadsig($generic, $scope);
      &path::remove_last($scope);
      $$generics_tbl{$generics_key} = $generic;
    }
  }
  foreach my $generic (@$big_cahuna) {
    if (&dakota::generate::is_va($generic)) {
      my $scope = [];
      &path::add_last($scope, 'dk');
      &path::add_last($scope, 'va');
      my $generics_key = &function::overloadsig($generic, $scope);
      &path::remove_last($scope);
      &path::remove_last($scope);
      $$generics_tbl{$generics_key} = $generic;
    }
  }
  my $generics_seq = [];
  #my $generic;
  while (my ($generic_key, $generic) = each(%$generics_tbl)) {
    &dakota::util::add_last($generics_seq, $generic);
    foreach my $arg (@{$$generic{'parameter-types'}}) {
      &add_type([$arg]);
    }
    foreach my $arg (@{$$generic{'keyword-types'} ||= []}) {
      &add_type([$arg]);
      &add_symbol($gbl_root, ['#' . $$arg{'name'}]);
    }
  }
  my $sorted_generics_seq = [sort method::compare @$generics_seq];
  $generics = $sorted_generics_seq;
  return ($generics, $symbols);
}
sub generics::_parse { # no longer recursive
  my ($data, $klass_scope) = @_;
  foreach my $method (values %{$$klass_scope{'methods'}}) {
    my $generic = &dakota::util::deep_copy($method);
    $$generic{'exported?'} = 0;
    #$$generic{'is-inline'} = 1;

    #if ($$generic{'alias'}) {
    #    $$generic{'name'} = $$generic{'alias'};
    #    delete $$generic{'alias'};
    #}

    #&dakota::util::add_last($data, $generic);
    &dakota::util::add_last($data, $generic);

    # not sure if we should type translate the return type
    $$generic{'return-type'} =
      &dakota::generate::type_trans($$generic{'return-type'});

    my $args    = $$generic{'parameter-types'};
    my $num_args = @$args;
    my $arg_num;
    for ($arg_num = 0; $arg_num < $num_args; $arg_num++) {
      $$args[$arg_num] = &dakota::generate::type_trans($$args[$arg_num]);
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
  while (my ($klass_name, $klass_scope) = each(%{$$file{'klasses'}})) {
    $$klass_names_set{'klasses'}{$klass_name} = undef;
    if (defined $klass_scope) {
      my $klass = 'klass';
      if (defined $$klass_scope{'klass'}) {
        $klass = $$klass_scope{'klass'};
      }
      $$klass_names_set{'klasses'}{$klass} = undef;
      my $superklass = 'object';
      if (defined $$klass_scope{'superklass'}) {
        $superklass = $$klass_scope{'superklass'};
      }
      $$klass_names_set{'klasses'}{$superklass} = undef;

      &add_direct_constructs($klass_names_set, $klass_scope, 'traits');
    }
  }
  if (exists $$file{'traits'}) {
    while (my ($klass_name, $klass_scope) = each(%{$$file{'traits'}})) {
      $$klass_names_set{'traits'}{$klass_name} = undef;
      if (defined $klass_scope) {
        &add_direct_constructs($klass_names_set, $klass_scope, 'traits');
      }
    }
  }
  return $klass_names_set;
}
sub init_global_rep {
  my ($reps) = @_;
  #my $reinit = 0;
  #if ($global_rep) { $reinit = 1; }
  #if ($reinit) { print STDERR &Dumper([keys %{$$global_rep{'klasses'}}]); }
  $global_rep = &rep_merge($reps);
  $global_rep = &kw_args_translate($global_rep);
  #if ($reinit) { print STDERR &Dumper([keys %{$$global_rep{'klasses'}}]); }
  return $global_rep;
}
sub parse_root {
  my ($gbl_sst_cursor) = @_;
  $gbl_current_scope = $gbl_root;

  # root
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^module$/) {
        &module_statement();
        last;
      }
      if (m/^export$/) {
        &export();
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
              &klass({'exported?' => 0});
              last;
            }
          }
        }
      }
      if (m/^trait$/) {
        my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
        if ($next_token) {
          if ($next_token =~ m/$id/) {
            &trait({'exported?' => 0});
            last;
          }
        }
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  foreach my $klass_type ( 'klasses', 'traits' ) {
    if (exists  $$gbl_root{'exported-headers'} &&
        defined $$gbl_root{'exported-headers'}) {
      while (my ($header, $dummy) =
               each(%{$$gbl_root{'exported-headers'}})) {
        $$gbl_root{'exported-headers'}{$header} = undef;
      }
      while (my ($klass, $info) = each(%{$$gbl_root{$klass_type}})) {
        if ($info) {
          $$info{'exported-headers'} = $$gbl_root{'exported-headers'};
        }
      }
    }
  }
  if (exists $$gbl_root{'generics'}) {
    delete $$gbl_root{'generics'}{'make'};
  }
  $$gbl_root{'should-generate-make'} = 1; # always generate make()
  return $gbl_root;
}
sub add_object_methods_decls_to_klass {
  my ($klass_scope, $methods_key, $slots_methods_key) = @_;
  if (exists $$klass_scope{$slots_methods_key}) {
    while (my ($slots_method_sig, $slots_method_info) =
             each (%{$$klass_scope{$slots_methods_key}})) {
      if ($$slots_method_info{'defined?'}) {
        my $object_method_info =
          &dakota::generate::convert_to_object_method($slots_method_info);
        my $object_method_signature =
          &function::overloadsig($object_method_info, undef);

        if (($$klass_scope{'methods'}{$object_method_signature} &&
             $$klass_scope{'methods'}{$object_method_signature}{'defined?'})) {
        } else {
          $$object_method_info{'defined?'} = 0;
          $$object_method_info{'is-generated'} = 1;
          #print STDERR "$object_method_signature\n";
          #print STDERR &Dumper($object_method_info);
          $$klass_scope{$methods_key}{$object_method_signature} =
            $object_method_info;
        }
      }
    }
  }
}
sub add_object_methods_decls {
  my ($root) = @_;
  #print STDERR &Dumper($root);

  foreach my $construct ('klasses', 'traits') {
    if (exists $$root{$construct}) {
      while (my ($klass_name, $klass_scope) =
               each (%{$$root{$construct}})) {
        &add_object_methods_decls_to_klass($klass_scope,
                                           'methods',
                                           'slots-methods');
      }
    }
  }
}
sub rep_tree_from_dk_path {
  my ($arg) = @_;
  $gbl_filename = $arg;
  #print STDERR &sst::filestr($gbl_sst);
  local $_ = &dakota::util::filestr_from_file($gbl_filename);
  while (m/^\s*\#\s*include\s+(<.*?>)/gm) {
    &add_system_include($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\#((0[xX][0-9a-fA-F]+|0[bB][01]+|0[0-7]+|[1-9]\d*)([uUiI](32|64|128))?)/g) {
    &add_int($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\#"(.*?)"/g) {
    &add_str($gbl_root, $1);
  }
  &encode_strings(\$_);
  my $parts = &encode_comments(\$_);

  $_ =~ s/\$/dk::/g;

  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #print STDERR $_;

  pos $_ = 0;
  $_ =~ s/(\bcase\s)\s+/$1/g;
  pos $_ = 0;
  while (m/(?<!\bcase\b)\s*($mid)\s*$colon/g) {
    &add_keyword($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/(?<!\bcase)\s*\#\'(.*?)\'\s*$colon/g) {
    &add_keyword($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\#\'(.*?)\'/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\bcase\s*"(.*)"\s*:/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\bcase\s*(\#.*)\s*:/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/(?<!\bcase)\s*\#($mid)/g) {
    &add_symbol($gbl_root, [$1]);
  }
  &decode_comments(\$_, $parts);
  &decode_strings(\$_);

  $gbl_sst = &sst::make($_, $gbl_filename);

  #$gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  #&add_klasses_used($gbl_root, $gbl_sst_cursor);

  $gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  &add_generics_used($gbl_root, $gbl_sst_cursor);

  my $result = &parse_root($gbl_sst_cursor);
  &add_object_methods_decls($result);
  #print STDERR &Dumper($result);
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
