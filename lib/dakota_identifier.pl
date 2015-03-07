#!/usr/bin/perl -w

use strict;
use warnings;

# 1    char idents: [_a-zA-Z]
# 2,3+ char idents: [_a-zA-Z][_a-zA-Z0-9-]*[_a-zA-Z0-9]
#
# [_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9])?

# dakota identifier
my $ident =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9])?/;
my $mident = qr/[_a-zA-Z][_a-zA-Z0-9-]*(?:\!|\?)?/;
my $tident = qr/[_a-zA-Z][_a-zA-Z0-9-]*-t/;

#print $ident . "\n";

foreach my $tkn (@ARGV) {
  if (0) {
  } elsif ($tkn =~ /^$mident$/) {
    print "Y-m..$tkn\n";
  } elsif ($tkn =~ /^$tident$/) {
    print "Y-t..$tkn\n";
  } elsif ($tkn =~ /^$ident$/) {
    print "Y....$tkn\n";
  } else {
    print "N....$tkn\n";
  }
}
