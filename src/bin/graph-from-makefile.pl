#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

# Copyright (C) 2007-2015 Robert Nielsen <robert@dakota.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

BEGIN {
  unshift @INC, "$ENV{'HOME'}/perl5/lib/perl5";
};

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys =  0;
$Data::Dumper::Indent    = 1;  # default = 2

use strict;
use warnings;

# interesting:
#   target : prereqs
#   .PHONY : prereqs
# not interesting:
#   target : variable :=|= values
#   variable :=|= values
#
# .anything : is special

sub add_dependency {
  my ($data, $target, $prereqs) = @_;
  if (0) {
  } elsif ($target =~ /^\.[_A-Z][_A-Z][_A-Z]+$/) {
    if (! $$data{'special-targets'}{$target}) {
      $$data{'special-targets'}{$target} = {};
    }
    foreach my $prereq (split(/\s+/, $prereqs)) {
      $$data{'special-targets'}{$target}{$prereq} = 1;
    }
  } elsif ($target =~ /^\.[a-zA-Z]+(\.[a-zA-Z]+)?$/) {
    if (! $$data{'suffix-rules'}{$target}) {
      $$data{'suffix-rules'}{$target} = {};
    }
    foreach my $prereq (split(/\s+/, $prereqs)) {
      $$data{'suffix-rules'}{$target}{$prereq} = 1;
    }
  } elsif ($target =~ /\%/) {
    if (! $$data{'pattern-rules'}{$target}) {
      $$data{'pattern-rules'}{$target} = {};
    }
    foreach my $prereq (split(/\s+/, $prereqs)) {
      $$data{'pattern-rules'}{$target}{$prereq} = 1;
    }
  } else {
    if (! $$data{'targets'}{$target}) {
      $$data{'targets'}{$target} = {};
    }
    foreach my $prereq (split(/\s+/, $prereqs)) {
      $$data{'targets'}{$target}{$prereq} = 1;
    }
  }
}
sub move_phony_targets {
  my ($data) = @_;

  foreach my $target (keys %{$$data{'targets'}}) {
    if ($$data{'special-targets'}{'.PHONY'}{$target}) {
      $$data{'phony-targets'}{$target} = $$data{'targets'}{$target};
      delete $$data{'targets'}{$target};
    }
  }
  return $data;
}
sub trim_empty_values {
  my ($data, $name) = @_;

  my ($key, $values);
  while (($key, $values) = each (%{$$data{$name}})) {
    if (0 == keys %$values) {
      delete $$data{$name}{$key};
    }
  }
}
sub makefile_db {
  my $data = {};
  open(my $fh, '-|', 'make --silent --print-data-base') or die $!;
  while (<$fh>) {
    if (/=/) {
      # not interested in any lin with an equal sign
      # not =
      # nor
      # not :=
    } else {
      if (0) {}
      elsif (m|^\s*(#.*?)$|s)               {} # eat comments
      elsif (m|^\s*(.*?)\s*:\s*(.*?)\s*$|s) { &add_dependency($data, $1, $2); }
    }
  }
  $data = &move_phony_targets($data);
  delete $$data{'suffix-rules'};
  delete $$data{'special-targets'};
  &trim_empty_values($data, 'pattern-rules');
  return $data;
}
sub is_terminal {
  my ($tbl) = @_;
  return !scalar keys %$tbl;
}
sub is_phony {
  my ($tbl, $name) = @_;
  my $result = 0;
  if ($$tbl{'phony-targets'}{$name}) {
    $result = 1;
  }
  return $result;
}
sub digraph {
  my ($db) = @_;
  my $result = 'digraph {' . "\n";
  $result .= '  graph [ rankdir = LR ];' . "\n";
  $result .= '  node [ shape = rect, style = rounded ];' . "\n";

  foreach my $goal (keys %{$$db{'phony-targets'}{'all'}}) {
    $result .= "  \"$goal\" [ color = green ];\n";
  }
  foreach my $KEY ('targets', 'phony-targets') {
    my ($key, $vals);

    while (($key, $vals) = each (%{$$db{$KEY}})) {
      my $non_phony_count = 0;
      my $edges = '';

      foreach my $target (keys %$vals) {
        if (!&is_phony($db, $target)) {
          $non_phony_count++;
        }
        # omit edge if destination end point is phony and terminal
        if (!&is_phony($db, $target) || !&is_terminal($$db{'phony-targets'}{$target})) {
          $edges .= "  \"$key\" -> \"$target\";\n";
        }
      }
      # omit edges if all end points are phony
      if (0 != $non_phony_count || !&is_phony($db, $key)) {
        $result .= $edges;
      }
    }
  }
  $result .= '}' . "\n";
  return $result;
}
sub start {
  my ($argv) = @_;
  my $db = &makefile_db({});
  if (1) {
    my $dbstr = &Dumper($db);
    $dbstr =~ s/\{\s*(".+?"\s*=>\s*\d+)\s*\}/\{ $1 \}/gs;
    print STDERR $dbstr;
  }
  print &digraph($db);
}
unless (caller) {
  &start(\@ARGV);
}
