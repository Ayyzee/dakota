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
use Cwd;
use File::Basename;
use Data::Dumper;
use Carp;

my $prefix;

BEGIN {
  $prefix = '/usr/local';
  if ($ENV{'DK_PREFIX'}) {
    $prefix = $ENV{'DK_PREFIX'};
  }
  unshift @INC, "$prefix/lib";
};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 ctlg_path_from_any_path
                 cxx_path_from_dk_path
                 cxx_path_from_so_path
                 init_global_rep
                 ka_translate
                 obj_path_from_cxx_path
                 obj_path_from_dk_path
                 rep_path_from_any_path
                 rep_path_from_ctlg_path
                 rep_path_from_dk_path
                 rep_path_from_so_path
                 str_from_cmd_info
                 colin
                 colout
                 add_klass_decl
                 add_trait_decl
                 add_symbol_ident
                 add_symbol
                 add_hash_ident
                 add_hash
                 add_keyword
                 add_string
              );

use dakota::sst;
use dakota::generate;

my $objdir = 'obj';
my $rep_ext = 'rep';
my $ctlg_ext = 'ctlg';
my $hxx_ext = 'h';
my $cxx_ext = 'cc';
my $dk_ext = 'dk';
my $obj_ext = 'o';

my $SO_EXT = undef;
if (!$ENV{'SO_EXT'}) {
  $ENV{'SO_EXT'} = 'so';
}                               # default SO_EXT
$SO_EXT = $ENV{'SO_EXT'};

# same code in dakota.pl and parser.pl
my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]?/;
my $wk = qr/[_A-Za-z]$k*[_A-Za-z0-9]*/; # dakota identifier
my $ak = qr/::?$k+/;            # absolute scoped dakota identifier
my $rk = qr/$k+$ak*/;           # relative scoped dakota identifier
my $d = qr/\d+/;
my $mx = qr/\!|\?/;
my $m  = qr/$z$mx?/;
my $h  = qr|[/._A-Za-z0-9-]|;

$ENV{'DKT-DEBUG'} = 0;

my $gbl_symbol_to_header = {
                            'AF-INET' => '<netinet/in.h>',
                            'AF-INET6' => '<netinet/in.h>',
                            'AF-LOCAL' => '<netinet/in.h>',

                            'EVFILT-READ' => '<sys/event.h>',
                            'EVFILT-WRITE' => '<sys/event.h>',
                            'EVFILT-PROC' => '<sys/event.h>',
                            'EVFILT-SIGNAL' => '<sys/event.h>',

                            'FILE' => '<cstdio>',
                            'INADDR-ANY' => '<netinet/in.h>',
                            'INADDR-LOOPBACK' => '<netinet/in.h>',
                            'INADDR-NONE' => '<netinet/in.h>',
                            'NULL' => '<cstddef>',
                            'SOCK-DGRAM' => '<sys/socket.h>',
                            'SOCK-RAW' => '<sys/socket.h>',
                            'SOCK-STREAM' => '<sys/socket.h>',
                            'in-addr' => '<netinet/in.h>',
                            'in-port-t' => '<netinet/in.h>',
                            'in6-addr' => '<netinet/in.h>',
                            'in6addr-any' => '<netinet/in.h>',
                            'in6addr-loopback' => '<netinet/in.h>',
                            'int8-t' => '<cstdint>',
                            'int16-t' => '<cstdint>',
                            'int32-t' => '<cstdint>',
                            'int64-t' => '<cstdint>',
                            'intmax-t' => '<cstdint>',
                            'intptr-t' => '<cstdint>',
                            'ip-mreq' => '<netinet/in.h>',
                            'ipv6-mreq' => '<netinet/in.h>',
                            'jmp-buf' => '<setjmp.h>',
                            'nullptr' => '<cstddef>',
                            'option' => '<getopt.h>',
                            'sa-family-t' => '<netinet/in.h>',
                            'sigaction' => '<signal.h>',
                            'siginfo-t' => '<signal.h>',
                            'size-t' => '<cstddef>',
                            'sockaddr-in' => '<netinet/in.h>',
                            'sockaddr-in6' => '<netinet/in.h>',
                            'sockaddr-un' => '<sys/un.h>',
                            'socklen-t' => '<sys/socket.h>',
                            'stat' => '<sys/stat.h>',
                            'struct in-addr' => '<netinet/in.h>',
                            'struct in6-addr' => '<netinet/in.h>',
                            'struct ip-mreq' => '<netinet/in.h>',
                            'struct ipv6-mreq' => '<netinet/in.h>',
                            'struct option' => '<getopt.h>',
                            'struct sigaction' => '<signal.h>',
                            'struct sockaddr-in' => '<netinet/in.h>',
                            'struct sockaddr-in6' => '<netinet/in.h>',
                            'struct sockaddr-un' => '<sys/un.h>',
                            'struct stat' => '<sys/stat.h>',
                            'uint8-t' => '<cstdint>',
                            'uint16-t' => '<cstdint>',
                            'uint32-t' => '<cstdint>',
                            'uint64-t' => '<cstdint>',
                            'uintmax-t' => '<cstdint>',
                            'uintptr-t' => '<cstdint>'
                           };
sub maybe_add_exported_header_for_symbol {
  my ($symbol) = @_;
  if ($$gbl_symbol_to_header{$symbol}) {
    &add_exported_header($$gbl_symbol_to_header{$symbol});
  }
}
sub maybe_add_exported_header_for_symbol_seq {
  my ($seq) = @_;
  foreach my $symbol (@$seq) {
    &maybe_add_exported_header_for_symbol($symbol);
  }
}
sub scalar_to_file {
  my ($file, $ref) = @_;
  if (!defined $ref) {
    print STDERR __FILE__, ":", __LINE__, ": ERROR: scalar_to_file($ref)\n";
  }
  my $refstr = &Dumper($ref);

  open(FILE, ">", $file) or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
  flock FILE, 2; # LOCK_EX
  truncate FILE, 0;
  print FILE $refstr;
  close FILE or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
}
sub ka_translate {
  my ($parse_tree) = @_;
  while (my ($generic, $discarded) = each(%{$$parse_tree{'generics'}})) {
    my $va_generic = $generic;

    if ($generic =~ s/^va://) {
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
          if ('va' eq &dakota::util::_first($$method{'name'})) {
            my $discarded;
            $discarded = &dakota::util::_remove_first($$method{'name'}); # lose 'va'
            $discarded = &dakota::util::_remove_first($$method{'name'}); # lose ':'
          }

          if ($$method{'ka-names'}) {
            my $ka_types = [];
            my $ka_name;        # not used
            foreach $ka_name (@{$$method{'ka-names'}}) {
              my $ka_type = &dakota::util::_remove_last($$method{'parameter-types'});
              &dakota::util::_add_last($ka_types, $ka_type);
            }
            &dakota::util::_add_last($$method{'parameter-types'}, [ 'va-list-t' ]);
            my $ka_defaults = [];
            my $ka_default;
            if (exists $$method{'ka-defaults'} && defined $$method{'ka-defaults'}) {
              while ($ka_default = &dakota::util::_remove_last($$method{'ka-defaults'})) {
                my $val = "@$ka_default";
                &dakota::util::_add_last($ka_defaults, $val);
              }
            }                   # if
            my $no_default = @$ka_types - @$ka_defaults;
            while ($no_default) {
              $no_default--;
              &dakota::util::_add_last($ka_defaults, undef);
            }
            $$method{'keyword-types'} = [];
            my $ka_type;
            while (scalar @$ka_types) {
              my $keyword_type = {
                                  type => &dakota::util::_remove_last($ka_types),
                                  default => &dakota::util::_remove_last($ka_defaults),
                                  name => &dakota::util::_remove_first($$method{'ka-names'}) };

              &dakota::util::_add_last($$method{'keyword-types'}, $keyword_type);
            }
            delete $$method{'ka-names'};
            delete $$method{'ka-defaults'};
          } else {
            my $name = &path::string($$method{'name'});
            my $ka_generics = &dakota::util::ka_generics();
            if (exists $$ka_generics{$name}) {
              if (!&dakota::generate::is_va($method)) {
                &dakota::util::_add_last($$method{'parameter-types'}, [ 'va-list-t' ]);
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
    } elsif (exists $$root_tbl{$key} && !defined $$root_tbl{$key} && defined $$tbl{$key}) {
      $$root_tbl{$key} = $$tbl{$key};
    }
  }
}
sub _rep_merge { # recursive
  my ($root_ref, $scope) = @_;
  my ($subscope_name, $subscope);

  foreach my $name ('klasses', 'traits', 'generics', 'symbols', 'keywords', 'exported-headers', 'exported-klass-decls', 'exported-trait-decls', 'strings', 'hashes', 'modules') {
    while (($subscope_name, $subscope) = each(%{$$scope{$name}})) {
      if ($subscope) {
	if (!defined $$root_ref{$name}{$subscope_name}) {
	  $$root_ref{$name}{$subscope_name} = &dakota::util::deep_copy($subscope);
	} elsif ('klasses' eq $name || 'traits' eq $name) {
	  &tbl_add_info($$root_ref{$name}{$subscope_name}{'methods'}, $$subscope{'methods'});
	  &tbl_add_info($$root_ref{$name}{$subscope_name}{'va-methods'}, $$subscope{'va-methods'});
	  &tbl_add_info($$root_ref{$name}{$subscope_name}{'raw-methods'}, $$subscope{'raw-methods'});

	  # need to merge 'slots' and bunch-o-stuff
	}
      } else {
	if (!exists $$root_ref{$name}{$subscope_name}) {
	  $$root_ref{$name}{$subscope_name} = undef;
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
    #if ($$parse_tree{'should-generate-make'})
    {
      $$root_ref{'should-generate-make'} = 1;
    }
    &_rep_merge($root_ref, $parse_tree);
  }
  return $root_ref;
}

my $gbl_sst = undef;
my $gbl_sst_cursor = undef;

my $gbl_root = {};
my $gbl_current_scope = $gbl_root;
my $gbl_current_module = undef;
my $gbl_filename = undef;
sub init_rep_from_dk_vars {
  my ($cmd_info) = @_;
  $gbl_root = {};
  $$gbl_root{'hashes'} = {};
  $$gbl_root{'keywords'} = {};
  $$gbl_root{'symbols'}  = {};
  $$gbl_root{'types'}  = {};
  $$gbl_root{'generics'}{'instance?'} = undef;
  $$gbl_root{'generics'}{'forward-iterator'} = undef;
  $$gbl_root{'generics'}{'next'} = undef;

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
  my $prefix = shift;
  for (@_) {
    chop $prefix while (! /^$prefix/);
  }
  return $prefix;
}
sub rel_path_canon { # should merge with canon_path()
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
sub rep_path_from_any_path {
  my ($path) = @_;
  die if !defined $SO_EXT;
  $path =~ s/\.$SO_EXT$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/$canon_path.$rep_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub cxx_path_from_so_path {
  my ($path) = @_;
  die if !defined $SO_EXT;
  $path =~ s/\.$SO_EXT$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/rt/$canon_path.$cxx_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub rep_path_from_so_path {
  my ($path) = @_;
  die if !defined $SO_EXT;
  $path =~ s/\.$SO_EXT$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/$canon_path.$rep_ext";
  $path =~ s|//|/|g;
  return $path;
}
#sub ctlg_rep_path_from_so_path
#{
#    my ($path) = @_;
#    $path =~ s/\.$SO_EXT$//;
#    my $canon_path = &rel_path_canon($path, undef);
#    $path = "$repdir/$canon_path.$ctlg_ext.$rep_ext";
#    return $path;
#}
sub rep_path_from_dk_path {
  my ($path) = @_;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/$canon_path.$rep_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub cxx_path_from_dk_path {
  my ($path) = @_;
  $path =~ s/\.$dk_ext$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/nrt/$canon_path.$cxx_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub obj_path_from_dk_path {
  my ($path) = @_;
  $path =~ s/\.$dk_ext$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/nrt/$canon_path.$obj_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub obj_path_from_cxx_path {
  my ($path) = @_;
  $path =~ s/\.$cxx_ext$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$canon_path.$obj_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub rep_path_from_ctlg_path {
  my ($path) = @_;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$canon_path.$rep_ext"; # already has leading objdir
  $path =~ s|//|/|g;
  return $path;
}
sub ctlg_path_from_any_path {
  my ($path) = @_;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/$canon_path.$ctlg_ext";
  $path =~ s|//|/|g;
  return $path;
}
sub ctlg_dir_path_from_so_path {
  my ($path) = @_;
  die if !defined $SO_EXT;
  $path =~ s/\.$SO_EXT$//;
  my $canon_path = &rel_path_canon($path, undef);
  $path = "$objdir/$canon_path";
  $path =~ s|//|/|g;
  return $path;
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
sub add_symbol_ident {
  my ($file, $ident) = @_;
  $$file{'symbols'}{$ident} = undef;
}
sub add_symbol {
  my ($file, $symbol) = @_;
  my $ident = &path::string($symbol);
  &add_symbol_ident($file, $ident);
}
sub add_type {
  my ($seq) = @_;
  &maybe_add_exported_header_for_symbol_seq($seq);
  my $ident = &path::string($seq);
  $$gbl_root{'types'}{$ident} = undef;
}
sub add_hash_ident {
  my ($file, $ident) = @_;
  $$file{'hashes'}{$ident} = undef;
}
sub add_hash {
  my ($file, $hash) = @_;
  my $ident = &path::string([$hash]);
  &add_hash_ident($file, $ident);
}
sub add_keyword {
  my ($file, $keyword) = @_;
  my $ident = &path::string([$keyword]);
  &add_hash_ident($file, $ident);
  &add_symbol_ident($file, $ident);
  $$file{'keywords'}{$ident} = undef;
}
sub add_string {
  my ($file, $string) = @_;
  $$file{'strings'}{$string} = undef;
}
sub token_seq::simple_seq {
  my ($tokens) = @_;
  my $seq = [];
  my $tkn;
  for $tkn (@$tokens) {
    &dakota::util::_add_last($seq, $$tkn{'str'});
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
    printf STDERR "%s:%i: expected \'%s\'\n",
      $file,
        $line,
          $match_token;
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
  $$gbl_root{'exported-headers'}{$tkn} = {};
}
sub header {
  my $tkn = &match_any();
  &match(__FILE__, __LINE__, ';');
  $$gbl_root{'headers'}{$tkn} = 1;
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
  $$gbl_current_scope{'exported-headers'} = &dakota::util::deep_copy($$gbl_root{'exported-headers'});
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
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) || '{' eq &sst_cursor::previous_token($gbl_sst_cursor) || '}' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &method({ 'exported?' => 0 });
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'traits'}) {
          $$gbl_current_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
          &dakota::util::_add_last($$gbl_current_scope{'traits'}, $trait);
        }
        last;
      }
      if (m/^require$/) {
        my ($body, $seq) = &dkdecl('require');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'requires'}) {
          $$gbl_current_scope{'requires'} = [];
        }
        &dakota::util::_add_last($$gbl_current_scope{'requires'}, &path::string($seq));
        last;
      }
      if (m/^provide$/) {
        my ($body, $seq) = &dkdecl('provide');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'provides'}) {
          $$gbl_current_scope{'provides'} = [];
        }
        &dakota::util::_add_last($$gbl_current_scope{'provides'}, &path::string($seq));
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
  my $tkn;
  my $type = [];
  foreach $tkn (@$tkns) {
    if (';' eq $$tkn{'str'}) {
      my $key = &dakota::util::_remove_last($type);
      &add_symbol($gbl_root, [$key]);      # slot var name
      &dakota::util::_add_last($seq, {$key => &arg::type($type)});
      &maybe_add_exported_header_for_symbol_seq($type);
      $type = [];
    } else {
      &dakota::util::_add_last($type, $$tkn{'str'});
    }
  }
  return;
}
sub enum_seq {
  my ($tkns, $seq) = @_;

  my $tkn;
  my $type = [];
  foreach $tkn (@$tkns) {
    if (',' eq $$tkn{'str'}) {
      my $key = &dakota::util::_remove_first($type);
      &add_symbol($gbl_root, [ $key ]);    # enum var name
      if ('=' ne &dakota::util::_remove_first($type)) {
        die __FILE__, ":", __LINE__, ": error:\n";
      }
      &dakota::util::_add_last($seq, { $key => "@$type" });
      &maybe_add_exported_header_for_symbol_seq($type);
      $type = [];
    } else {
      &dakota::util::_add_last($type, $$tkn{'str'});
    }
  }
  if (@$type && 0 != @$type) {
    my $key = &dakota::util::_remove_first($type);
    &add_symbol($gbl_root, [ $key ]);      # enum var name
    if ('=' ne &dakota::util::_remove_first($type)) {
      die __FILE__, ":", __LINE__, ": error:\n";
    }
    &dakota::util::_add_last($seq, { $key => "@$type" });
    &maybe_add_exported_header_for_symbol_seq($type);
  }
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
    &dakota::util::_add_last($type, $tkn);
  }
  my $cat = 'struct';
  if (@$type && 3 == @$type) {
    if ('enum' eq &dakota::util::_first($type)) {
      my $enum_base = &dakota::util::_remove_last($type);
      my $colon =    &dakota::util::_remove_last($type);
      die if ':' ne $colon;
      $$gbl_current_scope{'slots'}{'enum-base'} = $enum_base;
      #print STDERR &Dumper($$gbl_current_scope{'slots'});
    }
  }
  if (@$type && 1 == @$type) {
    if ('struct' eq &dakota::util::_first($type) ||
        'union' eq  &dakota::util::_first($type) ||
        'enum' eq   &dakota::util::_first($type)) {
      if ('enum' eq &dakota::util::_first($type)) {
        &add_symbol($gbl_root, ['enum-info']);
        &add_symbol($gbl_root, ['const-info']);

        &add_klass_decl($gbl_root, 'enum-info');
        &add_klass_decl($gbl_root, 'named-enum-info');
        &add_klass_decl($gbl_root, 'const-info');
      }
      $cat = &dakota::util::_remove_first($type);
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
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor);
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
    &dakota::util::_add_last($type, $tkn);
  }
  my $rhs = [];
  if ("@$type" =~ m/=/) {
    while ('=' ne &dakota::util::_last($type)) {
      &dakota::util::_add_first($rhs, &dakota::util::_remove_last($type));
    }
    &dakota::util::_remove_last($type); # '='
  }
  my $name = &dakota::util::_remove_last($type);
  &add_symbol($gbl_root, [ $name ]); # const var name
  if (@$type) {
    $$const{'type'} = &arg::type($type);
    $$const{'name'} = $name;
    $$const{'rhs'} = $rhs;
  }
  if (';' eq &sst_cursor::current_token($gbl_sst_cursor)) {
    &match(__FILE__, __LINE__, ';');
    &dakota::util::_add_last($$gbl_current_scope{'const'}, $const);
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
    &dakota::util::_add_last($type, $tkn);
  }
  if (@$type) {
    &add_type($type);
    $$enum{'type'} = &arg::type($type);
  }
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      &dakota::util::_add_last($$gbl_current_scope{'enum'}, $enum);
      return;
    }
    if (m/^\{$/) {
      if (@$type) {
        $$enum{'type'} = $type;
      }
      $$enum{'info'} = [];
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor);
      if ($open_curley_index + 1 != $close_curley_index) {
        my $enum_defs = &sst::token_seq($gbl_sst, $open_curley_index + 1, $close_curley_index - 1);
        &enum_seq($enum_defs, $$enum{'info'});
      }
      $$gbl_sst_cursor{'current-token-index'} = $close_curley_index + 1;
      &add_symbol($gbl_root, ['enum-info']);
      &add_symbol($gbl_root, ['const-info']);

      &add_klass_decl($gbl_root, 'enum-info');
      &add_klass_decl($gbl_root, 'named-enum-info');
      &add_klass_decl($gbl_root, 'const-info');
      &dakota::util::_add_last($$gbl_current_scope{'enum'}, $enum);
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
  if (&sst_cursor::current_token($gbl_sst_cursor) =~ m/$k+/) {
    &match_any();
    #&match(__FILE__, __LINE__, 'klass');
  }
  &match(__FILE__, __LINE__, ')');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root, ['initialize']);
      $$gbl_current_scope{'has-initialize'} = 1;
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor);
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
  if (&sst_cursor::current_token($gbl_sst_cursor) =~ m/$k+/) {
    &match_any();
    #&match(__FILE__, __LINE__, 'klass');
  }
  &match(__FILE__, __LINE__, ')');
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      &add_symbol($gbl_root, ['finalize']);
      $$gbl_current_scope{'has-finalize'} = 1;
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor);
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
sub include {
  &match(__FILE__, __LINE__, 'include');

  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^"$h+"$/) {
      &header();
      last;
    }
    if (m/^<$h+>$/) {
      &header();
      last;
    }

    $$gbl_sst_cursor{'current-token-index'}++;
  }
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
  my $first = &dakota::util::_remove_first($seq);
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
    &dakota::util::_add_last($seq, $token);
  }
  if (0 == @$seq) {
    $seq = undef;
  }
  return $seq;
}
sub module_import {
  my ($module_name) = @_;
  my $tbl = {};
  &match(__FILE__, __LINE__, 'module');
  my $imported_module_name = &match_re(__FILE__, __LINE__, $z);
  while (1) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (0) {
      } elsif (m/^;$/) {
        if (!exists $$gbl_root{'modules'}{$module_name}{'import'}{'module'}{$imported_module_name}) {
          $$gbl_root{'modules'}{$module_name}{'import'}{'module'}{$imported_module_name} = $tbl;
        }
        return;                 # leaving ';' as the current token
      } elsif (m/^,$/) {
        &match(__FILE__, __LINE__, ',');
      } elsif (m/^module$/) {
        $$gbl_root{'modules'}{$module_name}{'import'}{'module'}{$imported_module_name} = $tbl;
        $tbl = {};
        &module_import($module_name);
      } elsif (m/^($z)$/) {
        my $name = &match_re(__FILE__, __LINE__, $z);
        $$tbl{$name} = 1;
      } else {
        die __FILE__, ":", __LINE__, ": error:\n";
      }
    }
  }
}
sub module_export {
  my ($module_name) = @_;
  my $tbl = {};
  while (1) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (0) {
      } elsif (m/^;$/) {
        $$gbl_root{'modules'}{$module_name}{'export'} = $tbl;
        return;                 # leaving ';' as the current token
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
  my $module_name = &match_re(__FILE__, __LINE__, $z);
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (0) {
    } elsif (m/^;$/) {
      &match(__FILE__, __LINE__, ';');
      $gbl_current_module = $module_name;
      return;
    } elsif (m/^export$/) {
      &match(__FILE__, __LINE__, 'export');
      &module_export($module_name);
    } elsif (m/^import$/) {
      &match(__FILE__, __LINE__, 'import');
      &module_import($module_name);
    } else {
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
      $$gbl_current_scope{'exported-klass-decls'} = &dakota::util::deep_copy($$gbl_root{'exported-klass-decls'});
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
  $$gbl_current_scope{'exported-headers'} = &dakota::util::deep_copy($$gbl_root{'exported-headers'});
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
        if (';' eq &sst_cursor::previous_token($gbl_sst_cursor) || '{' eq &sst_cursor::previous_token($gbl_sst_cursor) || '}' eq &sst_cursor::previous_token($gbl_sst_cursor)) {
          &method({ 'exported?' => 0 });
          last;
        }
      }
      if (m/^trait$/) {
        my $seq = &dkdecl_list('trait');
        &match(__FILE__, __LINE__, ';');
        if (!defined $$gbl_current_scope{'traits'}) {
          $$gbl_current_scope{'traits'} = [];
        }
        foreach my $trait (@$seq) {
          &add_trait_decl($gbl_root, $trait);
          &dakota::util::_add_last($$gbl_current_scope{'traits'}, $trait);
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
        &dakota::util::_add_last($$gbl_current_scope{'requires'}, $path);
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
        &dakota::util::_add_last($$gbl_current_scope{'provides'}, $path);
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
          &dakota::util::_add_last($$gbl_root{'interposers'}{$name}, $construct_name);
        } elsif ($$gbl_root{'interposers'}{$name}) {
          $$gbl_root{'interposers-unordered'}{$name} = $$gbl_root{'interposers'}{$name};
          delete $$gbl_root{'interposers'}{$name};
          &dakota::util::_add_last($$gbl_root{'interposers-unordered'}{$name}, $construct_name);
        } else {
          die __FILE__, ":", __LINE__, ": error:\n";
        }
        last;
      }
      if (m/^superklass$/) {
        if (&sst_cursor::previous_token($gbl_sst_cursor) ne '$') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$k+/) {
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
            &sst_cursor::previous_token($gbl_sst_cursor) ne ':') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$k+/) {
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
    &dakota::util::_add_last($parts, &sst_cursor::current_token($gbl_sst_cursor));
    $$gbl_sst_cursor{'current-token-index'}++;
  }

  #    if (':' ne $parts[0])
  #    {
  #        &dakota::util::_add_first($parts, ':');
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
      &dakota::util::_add_last($parts, $body);
      $body = '';
    }
    $$gbl_sst_cursor{'current-token-index'}++;
  }
  &dakota::util::_add_last($parts, $body);
  return $parts;
}
sub expand_type {
  my ($type) = @_;
  my $previous_token = '';

  for (my $i = 0; $i < @$type; $i++) {
    $previous_token = $$type[$i];
  }

  if (1 < @$type &&
      $$type[@$type - 1] =~ /$k+/) {
    &dakota::util::_remove_last($type);
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
      &dakota::util::_add_last($$result[$i], $tkn);
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
sub ka_offsets {
  my ($seq, $gbl_token) = @_;
  my $equalarrow = undef;
  my $i;
  for ($i = 0; $i < @$seq; $i++) {
    if ('=>' eq $$seq[$i]) {
      $equalarrow = $i;
    }
  }
  return ( $equalarrow );
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
            &dakota::util::_add_last($parameter_n, $$parameter_types[$i]);
            $i++;
          } else {
            $i++;
            &dakota::util::_add_last($params, $parameter_n);
            $parameter_n = [];
            next;
          }
        } elsif (m/^\($/) {
          $opens++;
          &dakota::util::_add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        } elsif (m/^\)$/) {
          $opens--;
          &dakota::util::_add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        } else {
          &dakota::util::_add_last($parameter_n, $$parameter_types[$i]);
          $i++;
        }
      }
    }
    $i++;
    &dakota::util::_add_last($params, $parameter_n);
  }
  #print STDERR Dumper $params;
  my $types = [];
  my $ka_names = [];
  my $ka_defaults = [];
  foreach my $type (@$params) {
    my ($equalarrow) = &ka_offsets($type);

    if ($equalarrow) {
      my $ka_name = $equalarrow - 1;
      my $ka_default = [splice(@$type, $equalarrow)];
      my $equalarrow_tkn = &dakota::util::_remove_first($ka_default);
      if (2 == @$ka_default) {
        if ('{' ne $$ka_default[0] && '}' ne $$ka_default[1]) {
          &dakota::util::_add_last($ka_defaults, $ka_default);
        }
      } else {
        &dakota::util::_add_last($ka_defaults, $ka_default);
      }
      my $ka_name_seq = [splice(@$type, $ka_name)];
      #print STDERR Dumper $ka_name_seq;
      #print STDERR Dumper $type;
      &dakota::util::_add_last($ka_names, &dakota::util::_remove_last($ka_name_seq));
    } else {
      my $ident = &dakota::util::_remove_last($type);
      if ($ident =~ m/\-t$/) {
        &dakota::util::_add_last($type, $ident);
      } elsif (!($ident =~ m/$k+/)) {
        &dakota::util::_add_last($type, $ident);
      }
    }
    &dakota::util::_add_last($types, $type);
  }

  if (0 == @$ka_names) {
    $ka_names = undef;
  }

  if (0 == @$ka_defaults) {
    $ka_defaults = undef;
  }
  return ($types, $ka_names, $ka_defaults);
}
sub add_klasses_used {
  my ($scope, $gbl_sst_cursor) = @_;
  my $seqs = [
              { 'pattern' => [ '?ident', ':', 'klass'   ], },
              { 'pattern' => [ '?ident', ':', 'box',    ], },
              { 'pattern' => [ '?ident', ':', 'unbox',  ], },
              { 'pattern' => [ '?ident', ':', 'slots-t' ], },
             ];
  my $size = &sst_cursor::size($gbl_sst_cursor);
  for (my $i = 0; $i < $size - 2; $i++) {
    my $first_index = $$gbl_sst_cursor{'first-token-index'} ||= 0;
    my $last_index = $$gbl_sst_cursor{'last-token-index'} ||= undef;
    my $new_sst_cursor = &sst_cursor::make($$gbl_sst_cursor{'sst'}, $first_index + $i, $last_index);

    foreach my $args (@$seqs) {
      my ($range, $matches) = &sst_cursor::match_pattern_seq($new_sst_cursor, $$args{'pattern'});
      if ($range) {
        my $name = &sst_cursor::str($new_sst_cursor, [0,0]);
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
  my $seqs = [
              { 'name' => 'supers',   'range' => [2,4], 'pattern' => [ 'dk', ':',  'va', ':', '?method-name', '(', 'super' ], },
              { 'name' => 'supers',   'range' => [2,2], 'pattern' => [ 'dk', ':',             '?method-name', '(', 'super' ], },
              { 'name' => 'generics', 'range' => [2,4], 'pattern' => [ 'dk', ':',  'va', ':', '?method-name'               ], },
              { 'name' => 'generics', 'range' => [2,2], 'pattern' => [ 'dk', ':',             '?method-name'               ], },

              { 'name' => 'generics', 'range' => [2,4], 'pattern' => [ 'selector', '(', 'va', ':', '?method-name', '('     ], },
              { 'name' => 'generics', 'range' => [2,2], 'pattern' => [ 'selector', '(',            '?method-name', '('     ], },

              { 'name' => 'generics', 'range' => [2,4], 'pattern' => [ 'signature', '(', 'va', ':', '?method-name', '('     ], },
              { 'name' => 'generics', 'range' => [2,2], 'pattern' => [ 'signature', '(',            '?method-name', '('     ], },

              { 'name' => 'generics', 'range' => [0,2], 'pattern' => [ 'va', ':',  'make', '('                 ], },
              { 'name' => 'generics', 'range' => [0,0], 'pattern' => [             'make', '('                 ], },
             ];
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
# 'va-methods'
# 'raw-methods'

# exported or not, raw or not, va or not

# exported-va-raw-methods
sub method {
  my ($args) = @_;
  &match(__FILE__, __LINE__, 'method');
  my $method = {};
  if ($$args{'exported?'}) {
    $$method{'exported?'} = 1;
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'alias') {
    &match(__FILE__, __LINE__, 'alias');
    &match(__FILE__, __LINE__, '(');
    my $alias = &match_re(__FILE__, __LINE__, "$k+");
    &match(__FILE__, __LINE__, ')');
    $$method{'alias'} = [ $alias ];
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'format-va-printf') {
    &match(__FILE__, __LINE__, 'format-va-printf');
    &match(__FILE__, __LINE__, '(');
    my $alias = &match_re(__FILE__, __LINE__, '\d+');
    &match(__FILE__, __LINE__, ')');
    if (!exists $$method{'attributes'}) {
      $$method{'attributes'} = [];
    }
    &dakota::util::_add_last($$method{'attributes'}, 'format-va-printf');
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'format-printf') {
    &match(__FILE__, __LINE__, 'format-printf');
    &match(__FILE__, __LINE__, '(');
    my $alias = &match_re(__FILE__, __LINE__, '\d+');
    &match(__FILE__, __LINE__, ')');
    if (!exists $$method{'attributes'}) {
      $$method{'attributes'} = [];
    }
    &dakota::util::_add_last($$method{'attributes'}, 'format-printf');
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'extern') {
    &warning(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
    &match(__FILE__, __LINE__, 'extern');
    $$method{'exported?'} = 1;
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'static') {
    &warning(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'});
    &match(__FILE__, __LINE__, 'static');
    $$method{'exported?'} = 0;
  }
  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'inline') {
    &match(__FILE__, __LINE__, 'inline');
    $$method{'is-inline'} = 1;
  }
  my ($open_paren_index, $close_paren_index)
    = &sst_cursor::balenced($gbl_sst_cursor);

  if ('object-t' eq &sst::at($gbl_sst, $open_paren_index + 1)) {
    if (',' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1) &&
        ')' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1)) {
      if ('self' ne &sst::at($gbl_sst, $open_paren_index + 1 + 1)) {
        &error(__FILE__, __LINE__, $open_paren_index + 1 + 1);
      }
    }
  }
  my $j;
  for ($j = $open_paren_index + 1; $j < $close_paren_index; $j++) {
    if ('klass' eq &sst::at($gbl_sst, $j)) {
      #&error(__FILE__, __LINE__, $j);
    }
  }
  my $last_name_token = $open_paren_index - 1;
  my $last_type_token = $last_name_token;
  $last_type_token--;

  if (':' eq &sst::at($gbl_sst, $last_type_token) ||
      ':' eq &sst::at($gbl_sst, $last_type_token)) { # huh?
    $last_type_token--;

    if ('va' eq &sst::at($gbl_sst, $last_type_token)) {
      $$method{'is-va'} = 1;
      $last_type_token--;
    } else {
      &error(__FILE__, __LINE__, $last_type_token);
    }
  }
  my $return_type = &sst::token_seq($$gbl_sst_cursor{'sst'}, $$gbl_sst_cursor{'current-token-index'}, $last_type_token);
  $return_type = &token_seq::simple_seq($return_type);

  if ('void' eq &path::string($return_type)) {
    $$method{'return-type'} = undef;
    &warning(__FILE__, __LINE__, $$gbl_sst_cursor{'current-token-index'}); # 'void' is not a recommended return type for a method
  } else {
    $$method{'return-type'} = $return_type;
  }
  $$method{'name'} = &sst::token_seq($gbl_sst, $last_type_token + 1, $last_name_token);
  $$method{'name'} = &token_seq::simple_seq($$method{'name'});
  $$gbl_root{'generics'}{"@{$$method{'name'}}"} = undef;

  if ($open_paren_index + 1 == $close_paren_index) {
    &error(__FILE__, __LINE__, $close_paren_index);
  }
  my $parameter_types = &sst::token_seq($gbl_sst, $open_paren_index + 1, $close_paren_index - 1);
  $parameter_types = &token_seq::simple_seq($parameter_types);
  my ($ka_parameter_types, $ka_names, $ka_defaults) = &parameter_list($parameter_types);
  $$method{'parameter-types'} = $ka_parameter_types;

  if ($ka_names) {
    &dakota::util::ka_generics_add("@{$$method{name}}");
  }
  if ($ka_names) {
    $$method{'ka-names'} = $ka_names;
  }
  if ($ka_defaults) {
    $$method{'ka-defaults'} = $ka_defaults;
  }
  $$gbl_sst_cursor{'current-token-index'} = $close_paren_index + 1;

  if (&sst_cursor::current_token($gbl_sst_cursor) eq 'throw') {
    &match(__FILE__, __LINE__, 'throw');
    my ($open_paren_index, $close_paren_index) = &sst_cursor::balenced($gbl_sst_cursor);

    if ($open_paren_index + 1 != $close_paren_index) {
      my $exception_types = &sst::token_seq($gbl_sst, $open_paren_index + 1, $close_paren_index - 1);
      $exception_types = &token_seq::simple_seq($exception_types);
      $$method{'exception-types'} = &types($exception_types);
    }
    $$gbl_sst_cursor{'current-token-index'} = $close_paren_index + 1;
  }
  for (&sst_cursor::current_token($gbl_sst_cursor)) {
    if (m/^\{$/) {
      $$method{'defined?'} = 1;
      $$method{'module'} = $gbl_current_module;
      my ($open_curley_index, $close_curley_index) = &sst_cursor::balenced($gbl_sst_cursor);
      my $block_sst_cursor = &sst_cursor::make($gbl_sst, $open_curley_index, $close_curley_index);
      #&errdump($block_sst_cursor);
      &add_generics_used($method, $block_sst_cursor);
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

  if (0) {}
  elsif (&dakota::generate::is_raw($method) && &dakota::generate::is_va($method)) { # 11
    if (!defined $$gbl_current_scope{'raw-methods'}) {
      $$gbl_current_scope{'raw-methods'} = {};
    }
    $$gbl_current_scope{'raw-methods'}{$signature} = $method;
  } elsif (&dakota::generate::is_raw($method) && !&dakota::generate::is_va($method)) { # 10
    if (!defined $$gbl_current_scope{'raw-methods'}) {
      $$gbl_current_scope{'raw-methods'} = {};
    }
    $$gbl_current_scope{'raw-methods'}{$signature} = $method;
  } elsif (!&dakota::generate::is_raw($method) && &dakota::generate::is_va($method)) { # 01
    if (!defined $$gbl_current_scope{'methods'}) {
      $$gbl_current_scope{'methods'} = {};
    }
    $$gbl_current_scope{'methods'}{$signature} = $method;
  } elsif (!&dakota::generate::is_raw($method) && !&dakota::generate::is_va($method)) { # 00
    if (!defined $$gbl_current_scope{'methods'}) {
      $$gbl_current_scope{'methods'} = {};
    }
    $$gbl_current_scope{'methods'}{$signature} = $method;
  }
  return;
}
my $global_root_cmd;
my $global_rep;
sub init_cxx_from_dk_vars {
  my ($cmd_info) = @_;
  $global_root_cmd = $cmd_info;
}
sub generics::klass_type_from_klass_name {
  my ($klass_name) = @_;
  my $klass_type;

  if (exists $$global_rep{'klasses'}{$klass_name}) {
    $klass_type = 'klass';
  } elsif (exists $$global_rep{'traits'}{$klass_name}) {
    $klass_type = 'trait';
  } else {
    my $rep_path_var = [join ':', @{$$global_root_cmd{'reps'}}];
    die __FILE__, ":", __LINE__, ": ERROR: klass/trait \"$klass_name\" absent from rep(s) \"@$rep_path_var\"\n";
  }
  return $klass_type;
}
sub generics::klass_scope_from_klass_name {
  my ($klass_name, $type) = @_; # $type currently unused (should be 'klasses' or 'traits')
  my $klass_scope;

  # should use $type
  if ($$global_rep{'klasses'}{$klass_name}) {
    $klass_scope = $$global_rep{'klasses'}{$klass_name};
  } elsif ($$global_rep{'traits'}{$klass_name}) {
    $klass_scope = $$global_rep{'traits'}{$klass_name};
  } else {
    my $rep_path_var = [join ':', @{$$global_root_cmd{'reps'}}];
    die __FILE__, ":", __LINE__, ": ERROR: klass/trait \"$klass_name\" absent from rep(s) \"@$rep_path_var\"\n";
  }
  return $klass_scope;
}

sub _add_indirect_klasses { # recursive
  my ($klass_names_set, $klass_name, $col) = @_;
  my $klass_scope = &generics::klass_scope_from_klass_name($klass_name);

  if (defined $$klass_scope{'klass'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'klass'}} = undef;

    if ('klass' ne $$klass_scope{'klass'}) {
      &_add_indirect_klasses($klass_names_set, $$klass_scope{'klass'}, &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'interpose'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'interpose'}} = undef;

    if ('object' ne $$klass_scope{'interpose'}) {
      &_add_indirect_klasses($klass_names_set, $$klass_scope{'interpose'}, &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'superklass'}) {
    $$klass_names_set{'klasses'}{$$klass_scope{'superklass'}} = undef;

    if ('object' ne $$klass_scope{'superklass'}) {
      &_add_indirect_klasses($klass_names_set, $$klass_scope{'superklass'}, &dakota::generate::colin($col));
    }
  }
  if (defined $$klass_scope{'traits'}) {
    foreach my $trait (@{$$klass_scope{'traits'}}) {
      $$klass_names_set{'traits'}{$trait} = undef;
      if ($klass_name ne $trait) {
	&_add_indirect_klasses($klass_names_set, $trait, &dakota::generate::colin($col));
      }
    }
  }
  if (defined $$klass_scope{'requires'}) {
    foreach my $reqr (@{$$klass_scope{'requires'}}) {
      $$klass_names_set{'requires'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
	&_add_indirect_klasses($klass_names_set, $reqr, &dakota::generate::colin($col));
      }
    }
  }
  if (defined $$klass_scope{'provides'}) {
    foreach my $reqr (@{$$klass_scope{'provides'}}) {
      $$klass_names_set{'provides'}{$reqr} = undef;
      if ($klass_name ne $reqr) {
	&_add_indirect_klasses($klass_names_set, $reqr, &dakota::generate::colin($col));
      }
    }
  }
}
sub add_indirect_klasses {
  my ($klass_names_set) = @_;
  foreach my $construct ('klasses', 'traits') {
    foreach my $klass_name (keys %{$$klass_names_set{$construct}}) {
      my $col;
      &_add_indirect_klasses($klass_names_set, $klass_name, $col = '');
    }
  }
}
sub generics::parse {
  my ($parse_tree) = @_;
  my $klass_names_set = &dk::klass_names_from_file($parse_tree);
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
          &dakota::util::_add_last($big_cahuna, $generic);
        }
      }
    }
  }
  foreach my $generic1 (@$big_cahuna) {
    if ($$generic1{'alias'}) {
      my $alias_generic = &dakota::util::deep_copy($generic1);
      $$alias_generic{'name'} = $$alias_generic{'alias'};
      delete $$alias_generic{'alias'};
      &dakota::util::_add_last($big_cahuna, $alias_generic);
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
    &dakota::util::_add_last($generics_seq, $generic);
    foreach my $arg (@{$$generic{'parameter-types'}}) {
      &add_type([$arg]);
    }
    foreach my $arg (@{$$generic{'keyword-types'} ||= []}) {
      &add_type([$arg]);
      $$symbols{$$arg{'name'}} = [$$arg{'name'}];
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

    #&dakota::util::_add_last($data, $generic);
    &dakota::util::_add_last($data, $generic);

    # not sure if we should type translate the return type
    $$generic{'return-type'} = &dakota::generate::type_trans($$generic{'return-type'});

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
  if (defined $$scope{$construct_type}) {
    foreach my $construct (@{$$scope{$construct_type}}) {
      $$klasses{$construct} = undef;
    }
  }
}
sub dk::klass_names_from_file {
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
  while (my ($klass_name, $klass_scope) = each(%{$$file{'traits'}})) {
    $$klass_names_set{'traits'}{$klass_name} = undef;
    if (defined $klass_scope) {
      &add_direct_constructs($klass_names_set, $klass_scope, 'traits');
    }
  }
  return $klass_names_set;
}
sub dk::file_basenames {
  my ($files_ref) = @_;
  my $list = [];
  foreach my $file (@$files_ref) {
    my ($name, $path, $suffix) = File::Basename::fileparse($file, "\.$k+");
    $path =~ s/^\.\///g;        # replace './' with ''
    &dakota::util::_add_last($list, "$path$name");
  }
  return $list;
}
sub init_global_rep {
  my ($reps) = @_;
  #my $reinit = 0;
  #if ($global_rep) { $reinit = 1; }
  #if ($reinit) { print STDERR &Dumper([keys %{$$global_rep{'klasses'}}]); }
  $global_rep = &rep_merge($reps);
  $global_rep = &ka_translate($global_rep);
  #if ($reinit) { print STDERR &Dumper([keys %{$$global_rep{'klasses'}}]); }
  return $global_rep;
}
sub parse_root {
  my ($gbl_sst_cursor) = @_;
  $gbl_current_scope = $gbl_root;
  $$gbl_root{'exported-headers'} = {};
  $$gbl_root{'exported-klass-decls'} = {};
  $$gbl_root{'exported-trait-decls'} = {};

  # root
  while ($$gbl_sst_cursor{'current-token-index'} < &sst::size($$gbl_sst_cursor{'sst'})) {
    for (&sst_cursor::current_token($gbl_sst_cursor)) {
      if (m/^include$/) {
        &include();
        last;
      }
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
        if (0 == $$gbl_sst_cursor{'current-token-index'} || &sst_cursor::previous_token($gbl_sst_cursor) ne ':') {
          my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
          if ($next_token) {
            if ($next_token =~ m/$k+/) {
              &klass({'exported?' => 0});
              last;
            }
          }
        }
      }
      if (m/^trait$/) {
        my $next_token = &sst_cursor::next_token($gbl_sst_cursor);
        if ($next_token) {
          if ($next_token =~ m/$k+/) {
            &trait({'exported?' => 0});
            last;
          }
        }
      }
      $$gbl_sst_cursor{'current-token-index'}++;
    }
  }
  foreach my $exported_mumble ('exported-headers', 'exported-klass-decls', 'exported-trait-decls') {
    if ($$gbl_root{$exported_mumble}) {
      my $klasses = {};
      while (my ($klass, $info) = each(%{$$gbl_root{'klasses'}})) {
        if ($info) {
          $$klasses{$klass} = undef;
        }
      }
      while (my ($path, $dummy) = each(%{$$gbl_root{$exported_mumble}})) {
        $$gbl_root{$exported_mumble}{$path} = $klasses;
      }
      while (my ($klass, $info) = each(%{$$gbl_root{'klasses'}})) {
        if ($info) {
          $$info{$exported_mumble} = $$gbl_root{$exported_mumble};
        }
      }
    }
  }
  #if (exists $$gbl_root{'generics'}{'make'}) {
  delete $$gbl_root{'generics'}{'make'};
  $$gbl_root{'generics'}{'init'} = undef;        # for make()
  $$gbl_root{'generics'}{'alloc'} = undef;       # for make()
  $$gbl_root{'should-generate-make'} = 1;
  #}
  return $gbl_root;
}
sub add_object_methods_decls_to_klass {
  my ($klass_scope, $methods_key, $raw_methods_key) = @_;
  while (my ($raw_method_sig, $raw_method_info) = each (%{$$klass_scope{$raw_methods_key}})) {
    if ($$raw_method_info{'defined?'}) {
      my $object_method_info = &dakota::generate::convert_to_object_method($raw_method_info);
      my $object_method_signature = &function::overloadsig($object_method_info, undef);

      if (($$klass_scope{'methods'}{$object_method_signature} &&
           $$klass_scope{'methods'}{$object_method_signature}{'defined?'})) {
      } else {
        $$object_method_info{'defined?'} = 0;
        $$object_method_info{'is-generated'} = 1;
        #print STDERR "$object_method_signature\n";
        #print STDERR &Dumper($object_method_info);
        $$klass_scope{$methods_key}{$object_method_signature} = $object_method_info;
      }
    }
  }
}
sub add_object_methods_decls {
  my ($root) = @_;
  #print STDERR &Dumper($root);

  foreach my $construct ('klasses', 'traits') {
    while (my ($klass_name, $klass_scope) = each (%{$$root{$construct}})) {
      &add_object_methods_decls_to_klass($klass_scope, 'methods', 'raw-methods');
    }
  }
}
sub rep_tree_from_dk_path {
  my ($arg) = @_;
  $gbl_filename = $arg;
  #print STDERR &sst::filestr($gbl_sst);
  local $_ = &dakota::util::filestr_from_file($gbl_filename);

  #my $__sub__ = (caller(0))[3];
  #&log_sub_name($__sub__);
  #print STDERR $_;

  while (m/($z)\s*=>/g) {
    &add_keyword($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/($m)\s*=>/g) {
    &add_keyword($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\$\'(.*?)\'\s*=>/g) {
    &add_keyword($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\$\'(.*?)\'/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/case\s*"(.*)"\s*:/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/case\s*\$(.*)\s*:/g) {
    &add_hash($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\$\"(.*?)\"/g) {
    &add_string($gbl_root, $1);
  }
  pos $_ = 0;
  while (m/\$($m)/g) {
    &add_symbol($gbl_root, [$1]);
  }
  $gbl_sst = &sst::make($_, $gbl_filename);
  $gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  #print STDERR &sst::filestr($$gbl_sst_cursor{'sst'});
  my $scope = $gbl_root;
  &add_generics_used($scope, $gbl_sst_cursor);
  &add_klasses_used($scope, $gbl_sst_cursor);
  $gbl_sst_cursor = &sst_cursor::make($gbl_sst);
  my $result = &parse_root($gbl_sst_cursor);
  &add_object_methods_decls($result);
  #print STDERR &Dumper($result);
  return $result;
}

1;
