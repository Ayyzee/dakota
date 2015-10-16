#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts = {};
&GetOptions($opts, 'output=s');

my $num_pass = 0;
my $num_failed_build = 0;
my $num_failed_run = 0;
my $failed_build = [];
my $failed_run = [];

my $dir;
foreach $dir (@ARGV) {
  #print "dakota-project --directory $dir name\n";
  my $name = `dakota-project --directory $dir name`;
  chomp $name;
  my $exe = "$dir/$name";
  if (! -e $exe) {
    print "fail  $exe\n";
    push @$failed_build, $exe;
    $num_failed_build++;
  } else {
    my $directory = $exe;
    $directory =~ s|/$name$||;
    print "make --directory $directory check\n";
    $ENV{'DK_DIR'} = $directory;
    my $output;
    if (0) {
      $output = `make --directory $directory check`;
    } else {
      $output = `make --directory $directory check 2>&1`;
    }

    my $status = $?;

    #print $output;

    if (0 == $status) {
      print "pass  $exe\n";
      $num_pass++;
    } else {
      print "fail  $exe (status = $status)\n";
      push @$failed_run, $exe;
      $num_failed_run++;
    }
  }
}

my $num_failed = $num_failed_build + $num_failed_run;
my $total = $num_pass + $num_failed;

if ($$opts{'output'}) {
  my $file = $$opts{'output'};
  open STDOUT, ">$file" or die __FILE__, ":", __LINE__, ": ERROR: $file: $!\n";
}

if (0 != $num_failed_build) {
  print "# build ($num_failed_build failure(s))\n";
  print "build_fail_exe_files :=\\\n";
  my $exe;
  foreach $exe (@$failed_build) {
    print " $exe\\\n";
  }
  print "\n";
}

if (0 != $num_failed_run) {
  print "# run ($num_failed_run failure(s))\n";
  print "run_fail_exe_files :=\\\n";
  my $exe;
  foreach $exe (@$failed_run) {
    print " $exe\\\n";
  }
  print "\n";
}
my $summary = sprintf("# summary: pass/total = %3i/%3i (%2i + %2i = %2i failure(s))\n",
                      $num_pass,
                      $total,
                      $num_failed_build,
                      $num_failed_run,
                      $num_failed);
print $summary;
