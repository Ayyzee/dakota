#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;

my $dir = $ENV{'DKT_DIR'};
die if !$dir;

while (<>) {
  if ($_ =~ m/^(.*?):/) {
    my $path = $1;

    # if its a valid relative path
    if (!($path =~ m|^/|)) {
      if (-e $path) {
        print "$dir";
      }
    }
  }
  print $_;
}
