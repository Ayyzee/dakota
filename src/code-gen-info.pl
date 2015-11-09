#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

sub filestr {
  my ($path) = @_;
  local $/;
  open(my $in, "<", $path);
  my $filestr = <$in>;
  return $filestr;
}
my $nrt_hh = 'obj/nrt/string.hh';
my $rt_hh =  'obj/rt/dakota/lib/libdakota.hh';
my $rt_cc =  'obj/rt/dakota/lib/libdakota.cc';

my $args = [ $nrt_hh,
             $rt_hh,
             $rt_cc ];
my $tbl = {};

foreach my $arg (@$args) {
  #my $name = (split(/\//, $arg))[-1];
  my $filestr = &filestr($arg);
  #$arg =~ s|^obj/||;
  #$arg =~ s|^(n?rt)/.*/(.*)$|$1/$2|;
  $$tbl{$arg} = [];
  #print "$arg\n";

  while ($filestr =~ m/\s*#\s+undef\s+(\w+)/g) {
    push @{$$tbl{$arg}}, $1;
    #print "  $1\n";
  }
}
#use Data::Dumper; print STDERR &Dumper($tbl);
print "digraph {\n";
print "  graph [ rankdir = LR ];\n";
print "  graph [ page = \"8.5,11\", size = \"7.5,10\", center = true ];\n";
print "  node [ style = rounded, shape = rect, fontsize = 18, width = 3.5 ];\n";
print "\n";

foreach my $arg (@$args) {
  foreach my $nrt_element (@{$$tbl{$arg}}) {
    print "  \"$arg|$nrt_element\" [ label = $nrt_element ];\n";
  }
}
print "\n";
my $prev_arg = undef;
foreach my $arg (@$args) {
  if ($prev_arg) {
    my $prev_arg_tbl = { map { $_ => 1 } @{$$tbl{$prev_arg}} };
    my $arg_tbl =      { map { $_ => 1 } @{$$tbl{$arg}}      };

    foreach my $element (@{$$tbl{$prev_arg}}) {
      if ($$arg_tbl{$element}) {
        if ($element =~ m/^(.+?)_defns$/) {
          print "  \"$prev_arg|$element\" -> \"$arg|$element\" [ color = red ];\n";
        } else {
          print "  \"$prev_arg|$element\" -> \"$arg|$element\" [ color = blue ];\n";
        }
      } elsif ($element =~ m/^(.+?)_decls$/) {
        my $base = $1;
        if ($$arg_tbl{"${base}_defns"}) {
          print "  \"$prev_arg|${base}_decls\" -> \"$arg|${base}_defns\" [ color = green ];\n";
        }
      }
    }
  }
  $prev_arg = $arg;
}
print "\n";
foreach my $arg (@$args) {
  my $prev = undef;
  foreach my $nrt_element (@{$$tbl{$arg}}) {
    if ($prev) {
      print "  \"$arg|$prev\" -> \"$arg|$nrt_element\" [ style = invis ];\n";
    }
    $prev = $nrt_element;
  }
}
foreach my $arg (@$args) {
  print "  {\n";
  print "    graph [ rank = same ];\n";
  foreach my $nrt_element (@{$$tbl{$arg}}) {
    print "    \"$arg|$nrt_element\";\n";
  }
  print "  }\n";
}
print "}\n";
