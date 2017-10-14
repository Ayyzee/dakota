#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $gbl_prefix;
my $nl;

sub dk_prefix {
  my ($path) = @_;
  $path =~ s|//+|/|;
  $path =~ s|/\./+|/|;
  $path =~ s|^./||;
  if (-d "$path/bin" && -d "$path/lib") {
    return $path
  } elsif ($path =~ s|^(.+?)/+[^/]+$|$1|) {
    &dk_prefix($path);
  } else {
    die "Could not determine \$prefix from executable path $0: $!" . $nl;
  }
}

BEGIN {
  $nl = "\n";
  $gbl_prefix = &dk_prefix($0);
  unshift @INC, "$gbl_prefix/lib";
};
use Carp; $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

use dakota::dakota;
use dakota::parse;
use dakota::util;

sub array_stmt {
  my ($key, $items) = @_;
  my $result .= "set ($key" . $nl;
  foreach my $item (@$items) {
    $result .= '  ' . $item . $nl;
  }
  $result .= ')' . $nl;
  return $result;
}
my $tbl = &yaml_parse($ARGV[0]);
my $srcs = $$tbl{'srcs'};
delete $$tbl{'srcs'};
my $result = '# -*- mode: cmake -*-' . $nl;
foreach my $key (sort keys %$tbl) {
  my $val = $$tbl{$key};
  if (&is_array($val)) {
    $result .= &array_stmt($key, $val)
  } else {
    $result .= "set ($key $val)" . $nl;
  }
}
$result .= &array_stmt('srcs', $srcs);
print $result;
