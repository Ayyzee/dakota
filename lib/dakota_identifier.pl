#!/usr/bin/perl -w

use strict;
use warnings;

# 1    char idents: [_a-zA-Z]
# 2,3+ char idents: [_a-zA-Z][_a-zA-Z0-9-]*[_a-zA-Z0-9]
#
# [_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9])?

# dakota identifier (allows underscore in interior)
my $id =  qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]              )?/x;
my $mid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!])/x;
my $bid = qr/[_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  )/x;
my $tid = qr/[_a-zA-Z][_a-zA-Z0-9-]*-t/;

#print $id . "\n";

foreach my $tkn (@ARGV) {
  if (0) {
  } elsif ($tkn =~ /^$bid$/) {
    print "Y-b..$tkn\n";
  } elsif ($tkn =~ /^$mid$/) {
    print "Y-m..$tkn\n";
  } elsif ($tkn =~ /^$tid$/) {
    print "Y-t..$tkn\n";
  } elsif ($tkn =~ /^$id$/) {
    print "Y....$tkn\n";
  } else {
    print "N....$tkn\n";
  }
}
