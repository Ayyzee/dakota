#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;
use sort 'stable';
use Cwd;

my $gbl_prefix;
my $nl = "\n";

sub dk_prefix {
  my ($path) = @_;
  $path =~ s|//+|/|;
  $path =~ s|/\./+|/|;
  $path =~ s|^./||;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    &dk_prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!" . $nl;
  }
}

BEGIN {
  $gbl_prefix = &dk_prefix($0);
  unshift @INC, "$gbl_prefix/lib";
};
use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use dakota::dakota;
use dakota::parse;
use dakota::util;

use Data::Dumper;
$Data::Dumper::Terse =     1;
$Data::Dumper::Deepcopy =  1;
$Data::Dumper::Purity =    1;
$Data::Dumper::Useqq =     1;
$Data::Dumper::Sortkeys =  1;
$Data::Dumper::Indent =    1;   # default = 2

use Getopt::Long qw(GetOptionsFromArray);
$Getopt::Long::ignorecase = 0;

sub cmd_info_from_argv {
  my ($argv) = @_;
  my $root_cmd = {
    'opts' => {
    'var' => [],
    }
  };
  &GetOptionsFromArray($argv, $$root_cmd{'opts'},
                       'path-only',
                       'var=s',
                      );
  $$root_cmd{'inputs'} = $argv;
  &set_env_vars($$root_cmd{'opts'}{'var'});
  delete $$root_cmd{'opts'}{'var'};
  return $root_cmd;
}
sub start {
  my ($argv) = @_;
  my $cmd_info = &cmd_info_from_argv($argv);
  my $parts = &intmd_dir . '/parts.txt';
  if ($$cmd_info{'opts'}{'path-only'}) {
    print $parts . $nl;
    exit 0;
  }
  &make_dirname($parts);
  my $outstr = '';
  foreach my $input (@{$$cmd_info{'inputs'}}) {
    $outstr .= $input . $nl;
  }
  &filestr_to_file($outstr, $parts);
}
unless (caller) {
  &start(\@ARGV);
}
1;
