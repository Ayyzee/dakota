#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

$main::block = qr{
                   \{
                   (?:
                     (?> [^{}]+ )         # Non-braces without backtracking
                   |
                     (??{ $main::block }) # Group with matching braces
                   )*
                   \}
               }x;

$main::list = qr{
                  \(
                  (?:
                    (?> [^()]+ )         # Non-parens without backtracking
                  |
                    (??{ $main::list }) # Group with matching parens
                  )*
                  \)
              }x;

# same code in Dakota.pm
my $k  = qr/[a-z0-9-]+/;        # dakota identifer
my $ak = qr/:$k/;               # absolute scoped dakota identifier
my $rk = qr/$k$ak*/;            # relative scoped dakota identifier
undef $/;

my $root = { 'klass' => {}, 'trait' => {} };
my $klasses = {};
my $traits = {};
my $klass_to_superklass = {};
my $klass_to_traits = {};

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts= {};
&GetOptions($opts,
            'simple',
            'output=s',
            'directory=s',
          );

if ($$opts{output}) {
  open(STDOUT, ">$$opts{output}") or die("$$opts{output}: $!\n");
}

while (<>) {
  s/\/\/.*?$//gm;
  s/\/\*.*?\*\///gs;

  while (/(klass|trait)\s+($rk)\s*($main::block)/gc) {
    my $klass_type  = $1;
    my $klass_name  = $2;
    my $klass_block = $3;

    $$root{$klass_type}{$klass_name} = undef;

    if ('klass' eq $klass_type) {
      $$klasses{$klass_name} = undef;

      if ($klass_block =~ m/(superklass)\s+($rk)\s*;/) {
        my $decl_type = $1;
        my $decl_name = $2;

        $$root{$klass_type}{$klass_name}{$decl_type} = $decl_name;
      } else {
        $$root{$klass_type}{$klass_name}{'superklass'} = 'object';
      }
      $$klass_to_superklass{$klass_name} = $$root{$klass_type}{$klass_name}{'superklass'};
    } elsif ('trait' eq $klass_type) {
      $$traits{$klass_name} = undef;
    } else {
      die;
    }

    while ($klass_block =~ m/\s*(trait)\s+($rk)\s*;/gc) {
      my $decl_type = $1;
      my $decl_name = $2;

      if (!exists $$root{$klass_type}{$klass_name}{$decl_type}) {
        $$root{$klass_type}{$klass_name}{$decl_type} = [];
      }
      push @{$$root{$klass_type}{$klass_name}{$decl_type}}, $decl_name;

      $$klass_to_traits{$klass_name}{$decl_name} = undef;
    }
    pos($klass_block) = 0;
  }
}
#print STDERR Dumper $root;

# hashed or sorted
# immutable or mutable

my $hashed_only = undef;
my $sorted_only = undef;

my $immutable_only = 1;
my $mutable_only = undef;

my $nodes = '';
my $edges = '';

if (1) {
  foreach my $klass_name (keys %$klasses) {
    if ($klass_name =~ m/sorted/) {
      if ($klass_name =~ m/mutable/) {
        $nodes .= "\t\"$klass_name\" \[ shape = rect, color = blue \];\n";
      } else {
        $nodes .= "\t\"$klass_name\" \[ shape = rect, color = blue, fontcolor = red \];\n";
      }
    } elsif ($klass_name =~ m/hashed/) {
      if ($klass_name =~ m/mutable/) {
        $nodes .= "\t\"$klass_name\" \[ shape = rect, color = green \];\n";
      } else {
        $nodes .= "\t\"$klass_name\" \[ shape = rect, color = green, fontcolor = red \];\n";
      }
    } else {
      if ($klass_name =~ m/mutable/) {
        $nodes .= "\t\"$klass_name\" \[ shape = rect \];\n";
      } else {
        $nodes .= "\t\"$klass_name\" \[ shape = rect, fontcolor = red \];\n";
      }
    }
  }
  foreach my $trait_name (keys %$traits) {
    if ($trait_name =~ m/mutable/) {
      $nodes .= "\t\"$trait_name\" \[ shape = rect, color = cyan, style = rounded \];\n";
    } else {
      $nodes .= "\t\"$trait_name\" \[ shape = rect, color = cyan, fontcolor = red, style = rounded \];\n";
    }
  }

  my $dummy;
  my $klass_name;
  my $superklass_name;
  while (($klass_name, $superklass_name) = each %$klass_to_superklass) {
    if (keys %{$$root{'klass'}}) {
      $edges .= "\t\"$superklass_name\" -> \"$klass_name\" \[ dir = back \];\n";
    }
  }
  my $traits;
  while (($klass_name, $traits) = each %$klass_to_traits) {
    my $trait_name;
    foreach $trait_name (sort keys %$traits) {
      $edges .= "\t\"$trait_name\" -> \"$klass_name\" \[ dir = back, style = dashed \];\n";
    }
  }
}

my $page_width  =  8.5;
my $page_height = 11;

# 0.5 in margins
my $size_width  = 1 * (- 0.5 + $page_width  - 0.5);
my $size_height = 1 * (- 0.625 + $page_height - 0.625);

print "digraph dg\n\{\n";
print "\tgraph \[\n\t\trankdir = LR,\n\t\tpage = \"$page_width,$page_height\",\n\t\tsize = \"$size_width,$size_height\",\n\t\tfontname = courier,\n\t\tratio = fill\n\t\];\n";
print "\tnode \[\n\t\tshape = plaintext\n\t\];\n\n";
print $nodes;
print $edges;
print "}\n";
