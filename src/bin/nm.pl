#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $type_sig_addr = {};
my $sig_type_addr = {};
my $platform = lc(`uname -s`);
chomp $platform;

foreach my $lib (@ARGV) {
  # -g|--extern-only
  # -U|--defined-only
  # -o|-A|--print-file-name

  # -C|--demangle (not on darwin/OS X, thus the use of c++filt)
  my $cmds = {
    'darwin' => 'nm -g -U -o',  # darwin only supports short options
    'linux' =>  'nm --extern-only --defined-only --print-file-name --demangle'
  };
  foreach my $line (`$$cmds{$platform} $lib`) {
    if ($line =~ m|^(.+?):?\s+(.+?)\s+(.+?)\s+(.+)$|) {
      my ($file, $addr, $type, $sig) = ($1, $2, $3, $4);

      if ($platform eq 'darwin') {
        $sig =~ s|^_([^_]+)|$1|; # stupid Kevin Enderby!
        $sig = `c++filt $sig`; chomp $sig;
        $sig =~ s/__va_list_tag\*/va_list/; # fixups
      }
      $$type_sig_addr{$file}{$type}{$sig} = $addr;
      $$sig_type_addr{$file}{$sig}{$type} = $addr;
    } else {
      die $line;
    }
  }
}

my $delim = "";
foreach my $lib (sort keys %$sig_type_addr) {
  print $delim;
  foreach my $sig (sort keys %{$$sig_type_addr{$lib}}) {
    foreach my $type (keys %{$$sig_type_addr{$lib}{$sig}}) { # keys of types will return an array of len one
      my $short_lib = $lib;
      $short_lib =~ s|^.*/||;
      print "$short_lib  $type  $sig\n"; # we really don't care about the address
    }
  }
  $delim = "\n";
}
