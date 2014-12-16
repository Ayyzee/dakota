#!/usr/bin/perl -w

use strict;
use warnings;

my $alnum = qr/[A-Za-z0-9]/;
my $ident =   qr/(_+|_+$alnum+|[A-Za-z]$alnum*)(-$alnum+)*_*[!?]?/;
my $ident_t =    qr/(_+$alnum+|[A-Za-z]$alnum*)(-$alnum+)*?-t/;

foreach my $tkn (@ARGV) {
  if (0) {
  } elsif ($tkn =~ /^$ident_t$/) {
    print "Y-t..$tkn\n";
  } elsif ($tkn =~ /^$ident$/) {
    print "Y....$tkn\n";
  } else {
    print "N....$tkn\n";
  }
}
