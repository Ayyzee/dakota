#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $aggregate_slots_types = [
  '',
  'struct',
 #'struct : base_t',
 #'struct : base1_t, base2_t',
  'enum',
  'enum : int-t',
  'enum : uint8-t',
  'union',
];
my $sample_primitive_or_typedef_types = [
  'char8-t[64]',
  'object-t (*)(object-t, uint32-t)',
  'int32-t**'
];
my $decl_defn = [
 #'; ',
  '{}'
];
&start(\@ARGV);
sub start {
  my ($argv) = @_;

  print "module dakota;\n\n";
  my $max_len = &max_len($aggregate_slots_types) + 1;
  my $n = 0;
  foreach my $tail (@$decl_defn) {
    foreach my $slots_type (@$aggregate_slots_types) {
      my $pad = &pad($max_len, $slots_type);
      my $in = "slots " . $slots_type . $pad . $tail; 
      my $klass_defn = sprintf("klass klass-%02i { %s }", $n, $in);
      print $klass_defn . "\n";
      $n++;
    }
  }
  print "\n";
  foreach my $slots_type (@$sample_primitive_or_typedef_types) {
    my $in = "slots " . $slots_type . ";";
    my $klass_defn = sprintf("klass klass-%02i { %s }", $n, $in);
    print $klass_defn . "\n";
    $n++;
  }
  print "klass aa::bb::cc { slots {} }" . "\n";
}
sub pad {
  my ($max_len, $str) = @_;
  my $result = '';
  my $str_len = length $str;
  $result = ' ' x ($max_len - $str_len);
  return $result;
}
sub max_len {
  my ($seq) = @_;
  my $max = 0;
  foreach my $str (@$seq) {
    my $len = length $str;
    $max = $len if $len > $max;
  }
  return $max;
}
