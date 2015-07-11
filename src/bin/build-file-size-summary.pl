#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;


sub size {
  my ($pat) = @_;
  my $size = `cat $pat | wc -c`;
  $size =~ s/\s*(\d+)\s*/$1/g;
  return $size;
}

sub summary {
  my ($pats) = @_;
  my $result = [];
  for my $pat (@$pats) {
    my $size = &size($pat);
    push @$result, sprintf("% 6iK %s", $size/1000, $pat);
  }
  return $result;
}
# first is authored, rest are compiled
my $pats = [ '*.dk',
             'obj/*.cc',
             'obj/nrt/*.{hh,cc}',
             'obj/rt/dakota/lib/*.{hh,cc}' ];

map { print $_ . "\n"; } @{&summary($pats)};

my $authored_size = &size($$pats[0]);
my $compiled_size = 0;
shift @$pats;
foreach my $pat (@$pats) {
  $compiled_size += &size($pat);
}
print "---\n";
printf("% 6iK %s\n", $authored_size/1000, 'authored-size');
printf("% 6iK %s (+%i%%)\n", $compiled_size/1000, 'compiled-size',
       $compiled_size/$authored_size * 100);
