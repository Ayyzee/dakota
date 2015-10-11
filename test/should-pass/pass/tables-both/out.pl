#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts = {};
&GetOptions($opts, 'output=s');
my $fh;

open($fh, "<", "/usr/share/dict/words") || die;

my $tbl = {};

while (<$fh>) {
  chomp;
  $$tbl{lc($_)} = uc($_);
}
#use Data::Dumper;
#print &Dumper($tbl);

print "struct str_pair_t { char const* first; char const* last; };\n";
print "\n";
print "static str_pair_t str_pair[] = {\n";

my $i = 0;
while (my ($first, $last) = each (%$tbl)) {
  if ($i == 32) { last; }
  $i++;
  print "  { .first = \"$first\", .last = \"$last\" },\n";
}
print "};\n";
