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

package dakota::dakota;

use strict;
use warnings;

my $gbl_compiler;
my $gbl_prefix;

sub dk_prefix {
  my ($path) = @_;
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
  $gbl_compiler = do "$gbl_prefix/lib/dakota/compiler.json"
    or die "do $gbl_prefix/lib/dakota/compiler.json failed: $!\n";
};

use dakota::util;
use dakota::parse;
use dakota::generate;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT= qw(
                 loop_merged_rep_from_dk
             );

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use File::Basename;
use File::Copy;

undef $/;
$" = '';

my $objdir = 'obj';
my $hh_ext = 'hh';
my $cc_ext = 'cc';

my $want_separate_rep_pass = 1; # currently required to bootstrap dakota
my $want_separate_precompile_pass = 0;
my $show_outfile_info = 0;
my $global_should_echo = 0;
my $exit_status = 0;
my $dk_construct = undef;

my $cxx_compile_pic_flags = &dakota::parse::var($gbl_compiler, 'CXX_COMPILE_PIC_FLAGS', undef);
my $cxx_output_flags =  &dakota::parse::var($gbl_compiler, 'CXX_OUTPUT_FLAGS',  undef);
my $cxx_shared_flags =  &dakota::parse::var($gbl_compiler, 'CXX_SHARED_FLAGS',  undef);
my $cxx_dynamic_flags = &dakota::parse::var($gbl_compiler, 'CXX_DYNAMIC_FLAGS', undef);

my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid) = &dakota::util::ident_regex();
my $msig_type = &method_sig_type_regex();
my $msig = &method_sig_regex();
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
    if ($arg =~ m|\.dk$| ||
          $arg =~ m|\.ctlg$|) {
      $root = &dakota::parse::rep_tree_from_dk_path($arg);
      &_add_last($rep_files, &rep_path_from_dk_path($arg));
    } elsif ($arg =~ m|\.rep$|) {
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
	    if ($str =~ /^($id)$/) {
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
	    } elsif ($str =~ /^($id)::(slots-t)$/) {
        my ($klass_name, $type_name) = ($1, $2);
        # klass slots
        #print STDERR "klass       slots:  $klass_name|$type_name\n";
        if ($$root{'klasses'}{$klass_name} &&
		    $$root{'klasses'}{$klass_name}{'slots'} &&
		    $$root{'klasses'}{$klass_name}{'slots'}{'module'} eq $name) {
          $$root{'klasses'}{$klass_name}{'slots'}{'exported?'} = 33;
        }
	    } elsif ($str =~ /^($id)::($msig)$/) {
        my ($klass_name, $method_name) = ($1, $2);
        # klass/trait method
        #print STDERR "klass/trait method $klass_name:$method_name\n";
        foreach my $constructs ('klasses', 'traits') {
          if ($$root{$constructs}{$klass_name} &&
                $$root{$constructs}{$klass_name}{'module'} eq $name) {
            foreach my $method_type ('slots-methods', 'methods') {
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
sub nrt::add_extra_generics {
  my ($file) = @_;
  my $generics = { # hardcoded
    'alloc' => undef,
    'forward-iterator' => undef,
    'init' => undef,
    'instance?' => undef,
    'next' => undef,
  };
  foreach my $generic (sort keys %$generics) {
    &add_generic($file, $generic);
  }
}
sub nrt::add_extra_keywords {
  my ($file) = @_;
  my $keywords = { # hardcoded
    'keyword' => undef,   # kw-args processing funcs (throw)
    'object' => undef,    # kw-args processing funcs (throw)
    'signature' => undef, # kw-args processing funcs (throw)
  };
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
sub rt::add_extra_keywords {
  my ($file) = @_;
  my $keywords = { # hardcoded
    'items' => undef,
    'kls' => undef,
    'message' => undef,
    'superkls' => undef,
    'symbol' => undef,
  };
  foreach my $keyword (sort keys %$keywords) {
    &add_keyword($file, $keyword);
  }
}
###
sub nrt::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = { # hardcoded
    'boole' => undef,
    'char8' => undef,
    'file' => undef,
    'input-stream' => undef, # std-input
    'keyword' => undef,
    'klass' => undef,
    'method' => undef,
    'methods' => undef,
    'missing-keyword-exception' => undef, # kw-args processing funcs (throw)
    'named-info' => undef,
    'no-such-keyword-exception' => undef, # kw-args processing funcs (throw)
    'object' => undef,
    'output-stream' => undef, # std-output, std-error
    'property' => undef,
    'selector' => undef,
    'signature' => undef,
    'symbol' => undef,
    'super' => undef,
    'str' => undef,
    'uchar8' => undef,
  };
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
sub rt::add_extra_klass_decls {
  my ($file) = @_;
  my $klass_decls = { # hardcoded
    'no-such-method-exception' => undef, # generic funcs (throw)
    'selector-node' => undef,
    'assoc-node' => undef,
    'va-method' => undef,
    'construct' => undef,
    # NONE
  };
  foreach my $klass_decl (sort keys %$klass_decls) {
    &add_klass_decl($file, $klass_decl);
  }
}
###
sub nrt::add_extra_symbols {
  my ($file) = @_;
  my $symbols = { # hardcoded
    # NONE
  };
  foreach my $symbol (sort keys %$symbols) {
    &dakota::parse::add_symbol($file, [ $symbol ]);
  }
}
sub rt::add_extra_symbols {
  my ($file) = @_;
  my $symbols = { # hardcoded
    'behavior-exported?' => undef,
    'bool-t' => undef, # hardcode typedef
    'cat' => undef,
    'char-t' => undef, # hardcode typedef
    'construct' => undef,
    'date' => undef,
    'enum' => undef,
    'enum-base' => undef,
    'executable' => undef,
    'exported-method-addresses' => undef,
    'exported-method-signatures' => undef,
    'exported-slots-method-addresses' => undef,
    'exported-slots-method-signatures' => undef,
    'exported?' => undef,
    'exports' => undef,
    'expr' => undef,
    'file' => undef,
    'imported-klasses' => undef,
    'imported-klasses-names' => undef,
    'int-t' => undef, # hardcode typedef
    'interpose-name' => undef,
    'interposers' => undef,
    'kw-args-method-signatures' => undef,
    'klass' => undef,
    'klass-defns' => undef,
    'klass-name' => undef,
    'library' => undef,
    'method' => undef,
    'method-addresses' => undef,
    'method-aliases' => undef,
    'method-signatures' => undef,
    'module' => undef,
    'name' => undef,
    'offset' => undef,
    'requires' => undef,
    'schar-t' => undef, # hardcode typedef
    'selectors' => undef,
    'selectors-va' => undef,
    'signatures' => undef,
    'signatures-va' => undef,
    'size' => undef,
    'slots-info' => undef,
    'slots-type' => undef,
    'state-exported?' => undef,
    'struct' => undef,
    'superklass-name' => undef,
    'time' => undef,
    'trait' => undef,
    'traits' => undef,
    'type' => undef,
    'uchar-t' => undef, # hardcode typedef
    'uint-t' => undef, # hardcode typedef
    'union' => undef,
    'va-method' => undef,
    'va-method-addresses' => undef,
    'va-method-signatures' => undef,
  };
  foreach my $symbol (sort keys %$symbols) {
    &dakota::parse::add_symbol($file, [ $symbol ]);
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
sub loop_cc_from_dk {
  my ($cmd_info, $should_echo) = @_;
  if ($should_echo) {
    $" = ' ';
    print STDERR "  &loop_cc_from_dk --output $$cmd_info{'opts'}{'output'} @{$$cmd_info{'inputs'}}\n";
    $" = '';
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
    if ($input =~ m|\.rep$|) {
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
    my $file = &dk::parse("$file_basename.dk");
    #print STDERR "$file_basename.dk\n";
    #print STDERR &Dumper($$file{'klasses'});
    my $directory = '.';
    my ($dk_cc_name, $cc_name);
    my ($dk_cc_path, $cc_path);
    my ($dk_cc_ext, $cc_ext1);

    if (!$$cmd_info{'opts'}{'stdout'}) {
      my ($output_dk_cc, $output_cc);

      if ($$cmd_info{'opts'}{'output'}) {
        $output_cc =    "$$cmd_info{'opts'}{'output'}";
        $output_dk_cc = "$$cmd_info{'opts'}{'output'}";
        $output_dk_cc =~ s|\.$cc_ext$|\.dk\.$cc_ext|g;
      } else {
        $output_cc =    "$file_basename.$cc_ext";         ###
        $output_dk_cc = "$file_basename.dk.$cc_ext"; ###
      }
      $output_dk_cc =~ s|/nrt/|/|g;
      ($dk_cc_name, $dk_cc_path, $dk_cc_ext) = fileparse("$directory/$output_dk_cc", "\.dk\.$cc_ext");
      ($cc_name, $cc_path, $cc_ext1) = fileparse("$directory/$output_cc", "\.$id");
    }
    &dakota::generate::empty_klass_defns();
    &dk::generate_dk_cc($file_basename, "$dk_cc_path$dk_cc_name");
    $cc_path =~ s|^\./||;
    $cc_path =~ s|/$||;

    &nrt::add_extra_symbols($file);
    &nrt::add_extra_klass_decls($file);
    &nrt::add_extra_keywords($file);
    &nrt::add_extra_generics($file);

    if (0) {
      #  for each translation unit create links to the linkage unit header file
    } else {
      &dakota::generate::generate_nrt_decl($cc_path, $file_basename, $file);
    }
    &dakota::generate::generate_nrt_defn($cc_path, $file_basename, $file);
  }
} # loop_cc_from_dk

my $root_cmd;
sub start {
  my ($cmd_info) = @_;
  #print STDERR &Dumper($cmd_info);
  $root_cmd = $cmd_info;

  if (!$$cmd_info{'opts'}{'compiler'}) {
    $$cmd_info{'opts'}{'compiler'} = &dakota::parse::var($gbl_compiler, 'CXX', undef);
  }
  if (!$$cmd_info{'opts'}{'compiler-flags'}) {
    $$cmd_info{'opts'}{'compiler-flags'} =
      &dakota::parse::var($gbl_compiler, 'CXXFLAGS', undef) .
      ' ' . $ENV{'EXTRA_CXXFLAGS'} .
      ' ' . &dakota::parse::var($gbl_compiler, 'CXX_WARNINGS_FLAGS', undef);
  }
  my $ld_soname_flags = &dakota::parse::var($gbl_compiler, 'LD_SONAME_FLAGS', undef);

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

  if ($ENV{'DKT_GENERATE_RUNTIME_FIRST'}) {
    # generate the single (but slow) runtime .o, then the user .o files
    # this might be useful for distributed building (initiating the building of the slowest first
    # or for testing runtime code generation
    # also, this might be useful if the runtime .h file is being used rather than generating a
    # translation unit specific .h file (like in the case of inline functions)
    if (!$$cmd_info{'opts'}{'compile'}) {
      &gen_rt_obj($cmd_info);
    }
    $cmd_info = &loop_obj_from_dk($cmd_info);
  } else {
     # generate user .o files first, then the single (but slow) runtime .o
    $cmd_info = &loop_obj_from_dk($cmd_info);
    if (!$$cmd_info{'opts'}{'compile'}) {
      &gen_rt_obj($cmd_info);
    }
  }

  if ($$cmd_info{'opts'}{'compile'} && exists $$cmd_info{'output'}) {
    my $last = &_last($$cmd_info{'inputs'});
    `mv $last $$cmd_info{'output'}`;
  }
  if ($$cmd_info{'opts'}{'compile'}) {
    if ($want_separate_precompile_pass) {
      $$cmd_info{'cmd'}{'cmd-major-mode-flags'} = $cxx_compile_pic_flags;
      &obj_from_cc($cmd_info);
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
    if ($arg =~ m|\.dk$| ||
        $arg =~ m|\.ctlg$|) {
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
    if ($arg =~ m|\.dk$| ||
        $arg =~ m|\.ctlg$|) {
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
    if ($arg =~ m|\.dk$| ||
          $arg =~ m|\.ctlg$|) {
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
      my $cc_path = &cc_path_from_dk_path($arg);
      my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$cc_cmd{'inputs'} = [ $arg ];
      $$cc_cmd{'output'} = $cc_path;
      $$cc_cmd{'reps'} = $$cmd_info{'reps'};
      &cc_from_dk($cc_cmd);
      my $obj_cmd = { 'opts' => $$cmd_info{'opts'} };
      $$obj_cmd{'inputs'} = [ $cc_path ];
      $$obj_cmd{'output'} = $obj_path;
      delete $$obj_cmd{'opts'}{'output'};
	    if ($$cmd_info{'opts'}{'precompile'}) {
        $$obj_cmd{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
      }
      &obj_from_cc($obj_cmd);
      &_add_last($outfiles, $obj_path);
    } else {
      &_add_last($outfiles, $arg);
    }
  }
  $$cmd_info{'inputs'} = $outfiles;
  delete $$cmd_info{'opts'}{'output'}; # hackhack
  return $cmd_info;
}
sub cc_from_dk {
  my ($cmd_info) = @_;
  my $cc_cmd = { 'opts' => $$cmd_info{'opts'} };
  $$cc_cmd{'cmd'} = '&loop_cc_from_dk';
  $$cc_cmd{'reps'} = $$cmd_info{'reps'};
  $$cc_cmd{'output'} = $$cmd_info{'output'};
  $$cc_cmd{'inputs'} = $$cmd_info{'inputs'};
  my $should_echo;
  &outfile_from_infiles($cc_cmd, $should_echo = 0);
}
sub obj_from_cc {
  my ($cmd_info) = @_;
  if (!$$cmd_info{'opts'}{'precompile'}) {
    my $obj_cmd = { 'opts' => $$cmd_info{'opts'} };
    $$obj_cmd{'cmd'} = $$cmd_info{'opts'}{'compiler'};
    $$obj_cmd{'cmd-major-mode-flags'} = $cxx_compile_pic_flags;
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
  my $cc_path = &cc_path_from_so_path($so_path);
  my $obj_path = &obj_path_from_cc_path($cc_path);
  &make_dir($cc_path);
  my ($path, $file_basename, $file) = ($cc_path, $cc_path, undef);
  $path =~ s|/[^/]*$||;
  $file_basename =~ s|^[^/]*/||;          # strip of leading obj/
  $file_basename =~ s|-rt\.$cc_ext$||;   # strip of leading obj/
  if ($$cmd_info{'reps'}) {
    &init_global_rep($$cmd_info{'reps'});
  }
  $file = &scalar_from_file($rep_path);
  $file = &kw_args_translate($file);
  $$file{'should-generate-make'} = 1;


  &rt::add_extra_symbols($file);
  &rt::add_extra_klass_decls($file);
  &rt::add_extra_keywords($file);

  &nrt::add_extra_symbols($file);
  &nrt::add_extra_klass_decls($file);
  &nrt::add_extra_keywords($file);
  &nrt::add_extra_generics($file);

  &dakota::generate::generate_rt_decl($path, $file_basename, $file);
  &dakota::generate::generate_rt_defn($path, $file_basename, $file);

  my $obj_info = {'opts' => {}, 'inputs' => [ $cc_path ], 'output' => $obj_path };
  if ($$cmd_info{'opts'}{'precompile'}) {
    $$obj_info{'opts'}{'precompile'} = $$cmd_info{'opts'}{'precompile'};
  }
  if ($$cmd_info{'opts'}{'compiler'}) {
    $$obj_info{'opts'}{'compiler'} = $$cmd_info{'opts'}{'compiler'};
  }
  if ($$cmd_info{'opts'}{'compiler-flags'}) {
    $$obj_info{'opts'}{'compiler-flags'} = $$cmd_info{'opts'}{'compiler-flags'};
  }
  &obj_from_cc($obj_info);
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

  if ($ENV{'DKT_FIXUP_STDERR'}) {
    if ($ENV{'DKT_INITIAL_WORKDIR'}) {
      open (STDERR, "|$gbl_prefix/bin/dakota-fixup-stderr.pl $ENV{'DKT_INITIAL_WORKDIR'}") or die;
    }
    else {
      open (STDERR, "|$gbl_prefix/bin/dakota-fixup-stderr.pl") or die;
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
        #print "    creating $output # output\n";
	    }

      if ('&loop_merged_rep_from_dk' eq $$cmd_info{'cmd'}) {
        $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
        delete $$cmd_info{'output'};
        delete $$cmd_info{'cmd'};
        delete $$cmd_info{'cmd-major-mode-flags'};
        delete $$cmd_info{'cmd-flags'};
        &loop_merged_rep_from_dk($cmd_info, $global_should_echo || $should_echo);
      } elsif ('&loop_cc_from_dk' eq $$cmd_info{'cmd'}) {
        $$cmd_info{'opts'}{'output'} = $$cmd_info{'output'};
        delete $$cmd_info{'output'};
        delete $$cmd_info{'cmd'};
        delete $$cmd_info{'cmd-major-mode-flags'};
        delete $$cmd_info{'cmd-flags'};
        &loop_cc_from_dk($cmd_info, $global_should_echo || $should_echo);
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

  if ($gbl_prefix) {
    $$ctlg_cmd{'cmd'} = "$gbl_prefix/bin/dakota-info";
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
