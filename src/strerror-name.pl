#!/usr/bin/perl -w

use strict;
use warnings;

my $err_set = {};

my $prefix = 'E';
foreach my $path (glob "/usr/include/{*/,}errno.h") {
  open(my $in, "<", $path) or die "cannot open < $path: $!";

  while (<$in>) {
    if (m/\#\s*define\s+($prefix[A-Z0-9]+)\s+($prefix[A-Z0-9]+|\d+)/) {
      my $err = $1;
      my $val = $2;
      $$err_set{$err} = undef;
    }
  }
  close($in);
}
foreach my $key (keys %$err_set) {
  print "\# if defined $key\n";
  print "  set_name($key, \"$key\");\n";
  print "\# endif\n";
}
