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

package dakota;

use strict;
use warnings;
use Cwd;

my $prefix;

BEGIN {
  $prefix = '/usr/local';
  if ($ENV{'DK_PREFIX'}) {
    $prefix = $ENV{'DK_PREFIX'};
  }
  unshift @INC, "$prefix/lib";
}
;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 loop_merged_rep_from_dk
             );

use dakota::util;
use dakota::parse;
use dakota::generate;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

use File::Basename;
use File::Copy;

undef $/;
$" = '';

my $objdir = 'obj';
my $rep_ext = 'rep';
my $ctlg_ext = 'ctlg';
my $hxx_ext = 'h';
my $cxx_ext = 'cc';
my $dk_ext = 'dk';
my $obj_ext = 'o';

my $want_separate_rep_pass = 1; # currently required to bootstrap dakota
my $want_separate_precompile_pass = 0;
my $show_outfile_info = 0;
my $global_should_echo = 0;
my $exit_status = 0;
my $dk_construct = undef;

my $cxx_compile_flags = '--compile -fPIC';
my $cxx_output_flags = '--output';
my $cxx_shared_flags = '--shared';   # default
my $cxx_dynamic_flags = '--dynamic'; # default

if (defined $ENV{'CXX_SHARED_FLAGS'}) {
  $cxx_shared_flags = $ENV{'CXX_SHARED_FLAGS'};
}

if (defined $ENV{'CXX_DYNAMIC_FLAGS'}) {
  $cxx_dynamic_flags = $ENV{'CXX_DYNAMIC_FLAGS'};
}

# same code in dakota.pl and parser.pl
my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]?/;
my $wk = qr/[_A-Za-z]$k*[A-Za-z0-9_]*/; # dakota identifier
my $ak = qr/::?$k+/;            # absolute scoped dakota identifier
my $rk = qr/$k+$ak*/;           # relative scoped dakota identifier
my $d = qr/\d+/;                # relative scoped dakota identifier
my $mx = qr/\!|\?/;
my $m  = qr/$z$mx?/;
my $msig_type = qr/object-t|slots-t|slots-t\s*\*/;
my $msig = qr/(va:)?$m(\($msig_type?\))?/;
sub loop_merged_rep_from_dk {
  my ($cmd_info, $should_echo) = @_; 
  if ($should_echo) {
    $" = ' ';
    print STDERR "  &loop_merged_rep_from_dk --output $$cmd_info{'opts'}{'output'} @{$$cmd_info{'inputs'}}\n";
    $" = '';
  }
  &dakota::parse::init_rep_from_dk_vars($cmd_info);
  my $rep_files = [];
  if ($$cmd_info{'reps'}) {
    $rep_files = $$cmd_info{'reps'};
  }
  foreach my $arg (@{$$cmd_info{'inputs'}}) {
    my $root;
    if ($arg =~ m|\.$dk_ext$| ||
          $arg =~ m|\.$ctlg_ext$|) {
      $root = &dakota::parse::rep_tree_from_dk_path($arg);
      &_add_last($rep_files, &rep_path_from_dk_path($arg));
    } elsif ($arg =~ m|\.$rep_ext$|) {
      $root = &scalar_from_file($arg);
      &_add_last($rep_files, $arg);
    } else {
      die __FILE__, ":", __LINE__, ": ERROR\n";
    }
    if (1 == @{$$cmd_info{'inputs'}}) {
      if ($$cmd_info{'opts'}{'output'} && !exists $$cmd_info{'opts'}{'ctlg'}) {
        &dakota::parse::scalar_to_file($$cmd_info{'opts'}{'output'}, $root);
      }
    }
  }
  if (1 < @{$$cmd_info{'inputs'}}) {
    if ($$cmd_info{'opts'}{'output'} && !exists $$cmd_info{'opts'}{'ctlg'}) {
      my $rep = &dakota::parse::rep_merge($rep_files);
      &dakota::parse::scalar_to_file($$cmd_info{'opts'}{'output'}, $rep);
    }
  }
}                               # loop_merged_rep_from_dk
sub add_visibility_file {
  my ($arg) = @_;
  #print STDERR "&add_visibility_file(path=\"$arg\")\n";
  my $root = &scalar_from_file($arg);
  &add_visibility($root);
  &dakota::parse::scalar_to_file($arg, $root);
}
sub add_visibility {
  my ($root) = @_;
  my $names = [keys %{$$root{'modules'}}];
  foreach my $name (@$names) {
    my $tbl = $$root{'modules'}{$name}{'export'};
    my $strs = [sort keys %$tbl];
    foreach my $str (@$strs) {
	    my $seq = $$tbl{$str};
	    #print STDERR "export module $name $str;\n";
	    if ($str =~ /^($z)$/) {
        my $klass_name = $1;
        # klass/trait
        #print STDERR "klass/trait:        $klass_name\n";
        if ($$root{'klasses'}{$klass_name} &&
		    $$root{'klasses'}{$klass_name}{'module'} eq $name) {
          $$root{'klasses'}{$klass_name}{'exported?'} = 22;
        }
        if ($$root{'traits'}{$klass_name}) {
          $$root{'traits'}{$klass_name}{'exported?'} = 22;
        }
	    } elsif ($str =~ /^($z):(slots-t)$/) {
        my ($klass_name, $type_name) = ($1, $2);
        # klass slots
        #print STDERR "klass       slots:  $klass_name|$type_name\n";
        if ($$root{'klasses'}{$klass_name} &&
		    $$root{'klasses'}{$klass_name}{'slots'} &&
		    $$root{'klasses'}{$klass_name}{'slots'}{'module'} eq $name) {
          $$root{'klasses'}{$klass_name}{'slots'}{'exported?'} = 33;
        }
	    } elsif ($str =~ /^($z):($msig)$/) {
        my ($klass_name, $method_name) = ($1, $2);
        # klass/trait method
        #print STDERR "klass/trait method $klass_name:$method_name\n";
        foreach my $constructs ('klasses', 'traits') {
          if ($$root{$constructs}{$klass_name} &&
                $$root{$constructs}{$klass_name}{'module'} eq $name) {
            foreach my $method_type ('raw-methods', 'methods') {
              #print STDERR &Dumper($$root{$constructs}{$klass_name});
              while (my ($sig, $scope) = each (%{$$root{$constructs}{$klass_name}{$method_type}})) {
                my $sig_min = &sig1($scope);
                if ($method_name =~ m/\(\)$/) {
                  $sig_min =~ s/\(.*?\)$/\(\)/;
                }
                #print STDERR "$sig == $method_name\n";
                #print STDERR "$sig_min == $method_name\n";
                if ($sig_min eq $method_name) {
                  #print STDERR "$sig == $method_name\n";
                  #print STDERR "$sig_min == $method_name\n";
                  $$scope{'exported?'} = 44;
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
sub sig1 {
  my ($scope) = @_;
  my $result = '';
  $result .= "@{$$scope{'name'}}";
  $result .= '(';
  $result .= "@{$$scope{'parameter-types'}[0]}";
  $result .= ')';
  return $result;
}
sub loop_cxx_from_dk {
  my ($cmd_info, $should_echo) = @_;
  if ($should_echo) {
    $" = ' ';
    print STDERR "  &loop_cxx_from_dk --output $$cmd_info{'opts'}{'output'} @{$$cmd_info{'inputs'}}\n";
    $" = '';
  }
  &dakota::parse::init_cxx_from_dk_vars($cmd_info);

  my $inputs = [];
  my $rep;
  if ($$cmd_info{'reps'}) {
    $rep = $$cmd_info{'reps'};
  } else {
    $rep = [];
  }

  foreach my $input (@{$$cmd_info{'inputs'}}) {
    if ($input =~ m|\.$rep_ext$|) {
      &_add_last($rep, $input);
    } else {
      &_add_last($inputs, $input);
    }
  }
  $$cmd_info{'reps'} = $rep;
  $$cmd_info{'inputs'} = $inputs;

  if ($$cmd_info{'reps'}) {
    &init_global_rep($$cmd_info{'reps'});
  }
  my $argv_length = @{$$cmd_info{'inputs'}};
  if (0 == $argv_length) {
    exit 1;
  }
  my $file_basenames = &dk::file_basenames($$cmd_info{'inputs'});
  foreach my $file_basename (@$file_basenames) {
    my $file = &dk::parse("$file_basename.$dk_ext");
    #print STDERR "$file_basename.$dk_ext\n";
    #print STDERR &Dumper($$file{'klasses'});
    my $directory = '.';
    my ($dk_cxx_name, $cxx_name);
    my ($dk_cxx_path, $cxx_path);
    my ($dk_cxx_ext, $cxx_ext1);

    if (!$$cmd_info{'opts'}{'stdout'}) {
      my ($output_dk_cxx, $output_cxx);

      if ($$cmd_info{'opts'}{'output'}) {
        $output_dk_cxx = "$$cmd_info{'opts'}{'output'}";
        $output_dk_cxx =~ s/\.$k+/.$dk_ext.$cxx_ext/;
        $output_cxx = "$$cmd_info{'opts'}{'output'}";
      } else {
        $output_dk_cxx = "$file_basename.$dk_ext.$cxx_ext"; ###
        $output_cxx = "$file_basename.$cxx_ext";            ###
      }
      $output_dk_cxx =~ s|/nrt/|/|g;
      ($dk_cxx_name, $dk_cxx_path, $dk_cxx_ext) = fileparse("$directory/$output_dk_cxx", "\.$dk_ext\.$cxx_ext");
      ($cxx_name, $cxx_path, $cxx_ext1) = fileparse("$directory/$output_cxx", "\.$k+");
    }
    &dakota::generate::empty_klass_defns();
    &dk::generate_dk_cxx($file_basename, $dk_cxx_path, $dk_cxx_name);
    $cxx_path =~ s|^\./||;
    $cxx_path =~ s|/$||;
    my $defn_tbl = &dakota::generate::generate_nrt_decl($cxx_path, $file_basename, $file, undef);
    #my $stack; my $col;
    #$$defn_tbl{'klasses-cxx'} = &dk::generate_cxx_footer($file, $stack = [], $col = '');
    &generate_nrt_defn($cxx_path, $file_basename, $file, $defn_tbl);
  }
} # loop_cxx_from_dk

my $root_cmd;
sub start {
  my ($cmd_info) = @_;
  $root_cmd = $cmd_info;

  if (!$$cmd_info{'opts'}{'compiler'}) {
    $$cmd_info{'opts'}{'compiler'} = $ENV{'CXX'};
  }

  if (!$$cmd_info{'opts'}{'compiler-flags'}) {
    $$cmd_info{'opts'}{'compiler-flags'} = "$ENV{'CXXFLAGS'} $ENV{'EXTRA_CXXFLAGS'}";
  }

  if ($ENV{'MAKEFLAGS'}) {
    my $makeflags = $ENV{'MAKEFLAGS'};
    #print "MAKEFLAGS: \"$makeflags\"\n";
  }
  my $ld_soname_flags = '-soname'; #default
  if (defined $ENV{'LD_SONAME_FLAGS'}) {
    $ld_soname_flags = $ENV{'LD_SONAME_FLAGS'};
  }

  if ($$cmd_info{'opts'}{'compile'}) {
    $dk_construct = undef;
  } elsif ($$cmd_info{'opts'}{'shared'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
	    $cxx_shared_flags .= " --for-linker $ld_soname_flags --for-linker $$cmd_info{'opts'}{'soname'}";
    }
    $dk_construct = 'construct::k_library';
  } elsif ($$cmd_info{'opts'}{'dynamic'}) {
    if ($$cmd_info{'opts'}{'soname'}) {
	    $cxx_dynamic_flags .= " --for-linker $ld_soname_flags --for-linker $$cmd_info{'opts'}{'soname'}";
    }
    $dk_construct = 'construct::k_library';
  } elsif (!$$cmd_info{'opts'}{'compile'}
             && !$$cmd_info{'opts'}{'shared'}
             && !$$cmd_info{'opts'}{'dynamic'}) {
    $dk_construct = 'construct::k_executable';
  } else {
    die __FILE__, ":", __LINE__, ": error:\n";
  }

  $$cmd_info{'output'} = $$cmd_info{'opts'}{'output'};
  print "creating $$cmd_info{'output'}\n";
  $cmd_info = &loop_rep_from_so($cmd_info);
  #if ($$cmd_info{'opts'}{'output'} =~ m/\.rep$/) # this is a real hackhack
  #{ &add_visibility_file($$cmd_info{'opts'}{'output'}); }
  if ($want_separate_rep_pass) {
    $cmd_info = &loop_rep_from_dk($cmd_info);
  }
  if ($$cmd_info{'opts'}{'output'} =~ m/\.rep$/) { # this is a real hackhack
    &add_visibility_file($$cmd_info{'opts'}{'output'});
  }

  if (1) {
     # generate user .o files first, then the single (but slow) runtime .o
    $cmd_info = &loop_obj_from_dk($cmd_info);
    if (!$$cmd_info{'opts'}{'compile'}) {
      &gen_rt_obj($cmd_info);
    }
  } else {
    # generate the single (but slow) runtime .o, then the user .o files
    # this might be useful for distributed building (initiating the building of the slowest first
    # or for testing runtime code generation
    if (!$$cmd_info{'opts'}{'compile'}) {
      &gen_rt_obj($cmd_info);
    }
    $cmd_info = &loop_obj_from_dk($cmd_info);
  }

  if ($$cmd_info{'opts'}{'compile'} && exists $$cmd_info{'output'}) {
    my $last = &_last($$cmd_info{'inputs'});
    `mv $last $$cmd_info{'output'}`;
  }
  if ($$cmd_info{'opts'}{'compile'}) {
    if ($want_separate_precompile_pass) {
      $$cmd_info{'cmd'}{'cmd-major-mode-flags'} = $cxx_compile_flags;
      &obj_from_cxx($cmd_info);
    }
  } else {
    $$cmd_info{'opts'}{'compiler-flags'} = " -ldl";

    if ($$cmd_info{'opts'}{'shared'}) {
	    $$cmd_info{'cmd'}{'cmd-major-mode-flags'} = $cxx_shared_flags;
	    &so_from_obj($cmd_info);
    } elsif ($$cmd_info{'opts'}{'dynamic'}) {
	    $$cmd_info{'cmd'}{'cmd-major-mode-flags'} = $cxx_dynamic_flags;
	    &dso_from_obj($cmd_info);
    } elsif (!$$cmd_info{'opts'}{'compile'}
               && !$$cmd_info{'opts'}{'shared'}
               && !$$cmd_info{'opts'}{'dynamic'}) {
	    &exe_from_obj($cmd_info);
    } else {
	    die __FILE__, ":", __LINE__, ": error:\n";
    }
  }
  return $exit_status;
}
sub loop_rep_from_so {
  my ($cmd_info) = @_;
  foreach my $arg (@{$$cmd_info{'inputs'}}) {
    if ($arg =~ m|\.$dk_ext$| ||
        $arg =~ m|\.$ctlg_ext$|) {
    } else {
      my $ctlg_path =     &ctlg_path_from_any_path($arg);
      my $ctlg_dir_path = &dakota::parse::ctlg_dir_path_from_so_path($arg);
      my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$ctlg_cmd{'output'} = $ctlg_path;
      $$ctlg_cmd{'output-directory'} = $ctlg_dir_path;
      $$ctlg_cmd{'inputs'} = [ $arg ];
      &ctlg_from_so($ctlg_cmd);
      my $rep_path = &rep_path_from_ctlg_path($ctlg_path);
      &ordered_set_add($$cmd_info{'reps'}, $rep_path, __FILE__, __LINE__);
      my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$rep_cmd{'output'} = $rep_path;
      $$rep_cmd{'inputs'} = [ $ctlg_path ];
      &rep_from_dk($rep_cmd);
      &add_visibility_file($$rep_cmd{'output'});
    }
  }
  return $cmd_info;
}
sub loop_rep_from_dk {
  my ($cmd_info) = @_;
  my $rep_files = [];
  foreach my $arg (@{$$cmd_info{'inputs'}}) {
    if ($arg =~ m|\.$dk_ext$| ||
        $arg =~ m|\.$ctlg_ext$|) {
      my $rep_path = &rep_path_from_dk_path($arg);
      my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$rep_cmd{'output'} = $rep_path;
      $$rep_cmd{'inputs'} = [ $arg ];
      &rep_from_dk($rep_cmd);
      &ordered_set_add($rep_files, $rep_path, __FILE__, __LINE__);
    }
    #if ($arg =~ m|((.*?)\.($SO_EXT))$|)
    #{
    #    my $rep_path = &ctlg_rep_path_from_so_path($arg);
    #    &ordered_set_add($$cmd_info{'reps'}, $rep_path, __FILE__, __LINE__);
    #}
  }
  if (0 != @$rep_files) {
    my $rep_path = &rep_path_from_any_path($$cmd_info{'output'});
    &ordered_set_add($$cmd_info{'reps'}, $rep_path, __FILE__, __LINE__);
    my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$rep_cmd{'output'} = $rep_path;
    $$rep_cmd{'inputs'} = $rep_files;
    &rep_from_dk($rep_cmd);
  }
  return $cmd_info;
}
sub gen_rt_obj {
  my ($cmd_info) = @_;
  print "  creating $$cmd_info{'output'}\n";
  $$cmd_info{'rep'} = &rep_path_from_any_path($$cmd_info{'output'});
  my $flags = $$cmd_info{'opts'}{'compiler-flags'};
  if ($dk_construct) {
    $flags .= " --define-macro DKT_CONSTRUCT=$dk_construct";
  }
  if ($$cmd_info{'opts'}{'soname'}) {
    $flags .= " --define-macro DKT_NAME=\\\"$$cmd_info{'opts'}{'soname'}\\\"";
  } else {
    $flags .= " --define-macro DKT_NAME=\\\"$$cmd_info{'output'}\\\"";
  }
  $$cmd_info{'opts'}{'compiler-flags'} = $flags;
  &rt_obj_from_rep($cmd_info);
}
sub loop_obj_from_dk {
  my ($cmd_info) = @_;
  my $outfiles = [];
  foreach my $arg (@{$$cmd_info{'inputs'}}) {
    if ($arg =~ m|\.$dk_ext$| ||
          $arg =~ m|\.$ctlg_ext$|) {
      my $obj_path = &obj_path_from_dk_path($arg);
      print "  creating $obj_path\n";
      if (!$want_separate_rep_pass) {
        my $rep_path = &rep_path_from_dk_path($arg);
        my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
        $$rep_cmd{'inputs'} = [ $arg ];
        $$rep_cmd{'output'} = $rep_path;
        &rep_from_dk($rep_cmd);
        &ordered_set_add($$cmd_info{'reps'}, $rep_path, __FILE__, __LINE__);
      }
      my $cxx_path = &cxx_path_from_dk_path($arg);
      my $cxx_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$cxx_cmd{'inputs'} = [ $arg ];
      $$cxx_cmd{'output'} = $cxx_path;
      $$cxx_cmd{'reps'} = $$cmd_info{'reps'};
      &cxx_from_dk($cxx_cmd);
      my $obj_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$obj_cmd{'inputs'} = [ $cxx_path ];
      $$obj_cmd{'output'} = $obj_path;
      delete $$obj_cmd{'opts'}{'output'};
	    if ($$cmd_info{'opts'}{'precompile'}) {
        $$obj_cmd{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
      }
      &obj_from_cxx($obj_cmd);
      &_add_last($outfiles, $obj_path);
    } else {
      &_add_last($outfiles, $arg);
    }
  }
  $$cmd_info{'inputs'} = $outfiles;
  delete $$cmd_info{'opts'}{'output'}; # hackhack
  return $cmd_info;
}
sub cxx_from_dk {
  my ($cmd_info) = @_;
  my $cxx_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$cxx_cmd{'cmd'} = '&loop_cxx_from_dk';
  $$cxx_cmd{'reps'} = $$cmd_info{'reps'};
  $$cxx_cmd{'output'} = $$cmd_info{'output'};
  $$cxx_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  &outfile_from_infiles($cxx_cmd, $should_echo = 0);
}
sub obj_from_cxx {
  my ($cmd_info) = @_;
  if (!$$cmd_info{'opts'}{'precompile'}) {
    my $obj_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$obj_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
    $$obj_cmd{'cmd-major-mode-flags'} = $cxx_compile_flags;
    $$obj_cmd{'cmd-flags'} = $$cmd_info{'opts'}{'compiler-flags'};
    $$obj_cmd{'output'} = $$cmd_info{'output'};
    $$obj_cmd{'inputs'} = $$cmd_info{'inputs'};
    my $should_echo;

    if (0) {
	    $$obj_cmd{'cmd-flags'} .= " -MMD";
	    &outfile_from_infiles($obj_cmd, $should_echo = 1);
	    $$obj_cmd{'cmd-flags'} =~ s/ -MMD//g;
    }
    &outfile_from_infiles($obj_cmd, $should_echo = 1);
  }
}
sub rt_obj_from_rep {
  my ($cmd_info) = @_;
  my $so_path = $$cmd_info{'output'};
  my $rep_path = &rep_path_from_so_path($so_path);
  my $cxx_path = &cxx_path_from_so_path($so_path);
  my $obj_path = &obj_path_from_cxx_path($cxx_path);
  &make_dir($cxx_path);
  my ($path, $file_basename, $file) = ($cxx_path, $cxx_path, undef);
  $path =~ s|/[^/]*$||;
  $file_basename =~ s|^[^/]*/||;          # strip of leading obj/
  $file_basename =~ s|-rt\.$cxx_ext$||;   # strip of leading obj/
  if ($$cmd_info{'reps'}) {
    &init_global_rep($$cmd_info{'reps'});
  }
  $file = &scalar_from_file($rep_path);
  $file = &ka_translate($file);

  my $defn_tbl = &generate_rt_decl($path, $file_basename, $file);
  &generate_rt_defn($path, $file_basename, $file, $defn_tbl);

  my $obj_info = {'opts' => {}, 'inputs' => [ $cxx_path ], 'output' => $obj_path };
  if ($$cmd_info{'opts'}{'precompile'}) {
    $$obj_info{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
  }
  if ($$cmd_info{'opts'}{'compiler'}) {
    $$obj_info{'opts'}{'compiler'} = $$cmd_info{'opts'}{'compiler'};
  }
  if ($$cmd_info{'opts'}{'compiler-flags'}) {
    $$obj_info{'opts'}{'compiler-flags'} = $$cmd_info{'opts'}{'compiler-flags'};
  }
  &obj_from_cxx($obj_info);
  &_add_first($$cmd_info{'inputs'}, $obj_path);
}
sub so_from_obj {
  my ($cmd_info) = @_;
  if (!$$cmd_info{'opts'}{'precompile'}) {
    my $so_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$so_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
    $$so_cmd{'cmd-major-mode-flags'} = $cxx_shared_flags;
    $$so_cmd{'cmd-flags'} = "$ENV{'EXTRA_LDFLAGS'} $$cmd_info{'opts'}{'compiler-flags'}";
    $$so_cmd{'output'} = $$cmd_info{'output'};
    $$so_cmd{'inputs'} = $$cmd_info{'inputs'};
    my $should_echo;
    &outfile_from_infiles($so_cmd, $should_echo = 1);
  }
}
sub dso_from_obj {
  my ($cmd_info) = @_;
  if (!$$cmd_info{'opts'}{'precompile'}) {
    my $so_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$so_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
    $$so_cmd{'cmd-major-mode-flags'} = $cxx_dynamic_flags;
    $$so_cmd{'cmd-flags'} = "$ENV{'EXTRA_LDFLAGS'} $$cmd_info{'opts'}{'compiler-flags'}";
    $$so_cmd{'output'} = $$cmd_info{'output'};
    $$so_cmd{'inputs'} = $$cmd_info{'inputs'};
    my $should_echo;
    &outfile_from_infiles($so_cmd, $should_echo = 1);
  }
}
sub exe_from_obj {
  my ($cmd_info) = @_;
  if (!$$cmd_info{'opts'}{'precompile'}) {
    my $exe_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$exe_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
    $$exe_cmd{'cmd-major-mode-flags'} = undef;
    $$exe_cmd{'cmd-flags'} = "$ENV{'EXTRA_LDFLAGS'} $$cmd_info{'opts'}{'compiler-flags'}";
    $$exe_cmd{'output'} = $$cmd_info{'output'};
    $$exe_cmd{'inputs'} = $$cmd_info{'inputs'};
    my $should_echo;
    &outfile_from_infiles($exe_cmd, $should_echo = 1);
  }
}
sub dir_part {
  my ($path) = @_;
  my $parts = [split /\//, $path];
  &dakota::util::_remove_last($parts);
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
  if ($global_should_echo || $should_echo) {
    print STDERR "  $cmd_str\n";
  }

  if (0 && ! $ENV{'DKT_NO_FIXUP_STDERR'}) {
    if ($ENV{'DKT_DIR'}) {
      my $cwd = &getcwd();
      open (STDERR, "|dakota-fixup-stderr.pl $cwd $ENV{'DKT_DIR'}") or die;
    }
    else {
      open (STDERR, "|dakota-fixup-stderr.pl") or die;
    }
  }

  my $exit_val = system($cmd_str);
  if (0 != $exit_val >> 8) {
    my $tmp_exit_status = $exit_val >> 8;
    if ($exit_status < $tmp_exit_status) { # similiar to behavior of gnu make
      $exit_status = $tmp_exit_status;
    }
    if (!$$root_cmd{'opts'}{'keep-going'}) {
      if (!($global_should_echo || $should_echo)) {
		    print STDERR "  $cmd_str\n";
      }
      die "exit value from system() was $exit_val\n" if $exit_status == 0;
      exit $exit_status;
    }
  }
}
  sub path_stat {
    my ($path_db, $path) = @_;
    my $stat;
    if (exists $$path_db{$path}) {
      $stat = $$path_db{$path};
    } else {
      if ($show_outfile_info) {
        print "STAT $path\n";
      }
      @$stat{qw(dev inode mode nlink uid gid rdev size atime mtime ctime blksize blocks)} = stat($path);
    }
    return $stat;
  }
sub append_to_env_file {
  my ($key, $elements, $env_var) = @_;
  my $file = $ENV{$env_var};

  if ($file) {
    my $elements_str = '';
    open FILE, ">>$ENV{$env_var}" or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
    foreach my $element (@$elements) {
      $elements_str .= "\"$element\",";
    }
    print FILE "  { \"$key\", [ $elements_str ] },\n";
    close FILE;
  }
}
sub outfile_from_infiles {
  my ($cmd_info, $should_echo) = @_;
  my $outfile = $$cmd_info{'output'};
  &append_to_env_file($outfile, $$cmd_info{'inputs'}, "DKT_DEPENDS_OUTPUT_FILE");
  my $file_db = {};
  my $outfile_stat = &path_stat($file_db, $$cmd_info{'output'});
  foreach my $infile (@{$$cmd_info{'inputs'}}) {
    my $infile_stat = &path_stat($file_db, $infile);
    if (!$$infile_stat{'mtime'}) {
      $$infile_stat{'mtime'} = 0;
    }

    if (! -e $outfile || $$outfile_stat{'mtime'} < $$infile_stat{'mtime'}) {
      &make_dir($$cmd_info{'output'});
      if ($show_outfile_info) {
        print "MK $$cmd_info{'output'}\n";
      }
	    my $output = $$cmd_info{'output'};

	    if ($output !~ m|\.rep$| &&
          $output !~ m|\.ctlg$|) {
        $should_echo = 0;
        if ($ENV{'DKT_DIR'} && '.' ne $ENV{'DKT_DIR'} && './' ne $ENV{'DKT_DIR'}) {
          $output = $ENV{'DKT_DIR'} . '/' . $output
        }
        print "    creating $output\n"; # output
        #print "    creating $output # output\n";
	    }

      if ('&loop_merged_rep_from_dk' eq $$cmd_info{'cmd'}) {
        $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
        delete $$cmd_info{'output'};
        delete $$cmd_info{'cmd'};
        delete $$cmd_info{'cmd-major-mode-flags'};
        delete $$cmd_info{'cmd-flags'};
        &loop_merged_rep_from_dk($cmd_info, $global_should_echo || $should_echo);
      } elsif ('&loop_cxx_from_dk' eq $$cmd_info{'cmd'}) {
        $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
        delete $$cmd_info{'output'};
        delete $$cmd_info{'cmd'};
        delete $$cmd_info{'cmd-major-mode-flags'};
        delete $$cmd_info{'cmd-flags'};
        &loop_cxx_from_dk($cmd_info, $global_should_echo || $should_echo);
      } else {
        &exec_cmd($cmd_info, $should_echo);
      }
      last;
    } else {
      if ($show_outfile_info) {
        print "OK $$cmd_info{'output'}\n";
      }
    }
  }
}
sub rep_from_dk {
  my ($cmd_info) = @_;
  my $rep_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$rep_cmd{'cmd'} = '&loop_merged_rep_from_dk';
  $$rep_cmd{'output'} = $$cmd_info{'output'};
  $$rep_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  &outfile_from_infiles($rep_cmd, $should_echo = 0);
}
sub ctlg_from_so {
  my ($cmd_info) = @_;
  my $ctlg_cmd = { 'opts' => $$cmd_info{'opts'} };

  if ($ENV{'DK_PREFIX'}) {
    $$ctlg_cmd{'cmd'} = "$ENV{'DK_PREFIX'}/bin/dakota-info";
  } else {
    $$ctlg_cmd{'cmd'} = 'dakota-info';
  }

  $$ctlg_cmd{'output'} = $$cmd_info{'output'};
  $$ctlg_cmd{'output-directory'} = $$cmd_info{'output-directory'};
  $$ctlg_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  &outfile_from_infiles($ctlg_cmd, $should_echo = 0);
}
sub ordered_set_add {
  my ($ordered_set, $element, $file, $line) = @_;
  foreach my $member (@$ordered_set) {
    if ($element eq $member) {
      #printf STDERR "%s:%i: warning: element \"$element\" already present\n", $file, $line;
      return;
    }
  }
  &_add_last($ordered_set, $element);
}
1;
