#!/usr/bin/perl
# -*- mode: cperl -*-

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Indent = 1;

my $ds = {};

$main::block = qr{
                   \{
                   (?:
                     (?> [^{}]+ )         # Non-braces without backtracking
                   |
                     (??{ $main::block }) # Group with matching braces
                   )*
                   \}
               }x;

$main::block_in = qr{
                      (?:
                        (?> [^{}]+ )         # Non-braces without backtracking
                      |
                        (??{ $main::block }) # Group with matching braces
                      )*
                  }x;

sub tighten
{
  my ($str) = @_;
  $str =~ s/^\s+//gms; # remove leading ws
  $str =~ s/\s+$//gms; # remove trailing ws
  $str =~ s/\s+/ /gms; # replace multiple ws with single ws
  return $str;
}

sub counted_set::add
{
  my ($set, $element) = @_;

  if (!defined $$set{$element}) {
    $$set{$element} = 0;
  }
  $$set{$element}++;
}

undef $/;
foreach my $file (@ARGV) {
  my $fh;
  open($fh, "<", $file);
  my $filestr = <$fh>;
  close($fh);
  my $pkg = &pkg_from_path($file);
  $filestr =~ s/#.*?\n/\n/gms; # remove comments

  $filestr =~ /\@EXPORT\s*=\s*qw\((.+?)\)/gms;
  foreach my $exported_sub (split(/\s+/, &tighten($1))) {
    $$ds{$pkg}{'*export*'}{"$exported_sub()"} = undef;
  }
  while ($filestr =~ /^\s*use\s+((\w+::)*\w+)\s*;/gms) {
    $$ds{$pkg}{'*use*'}{"$1\()"} = undef;
  }
  while ($filestr =~ /^\s*sub\s+((\w+::)*\w+)\s*\{($main::block_in)\}/gms) {
    my ($sub_name, $block_in) = ($1, $3);
    if (!defined $$ds{$pkg}{"$sub_name()"}) {
      $$ds{$pkg}{'*sub*'}{"$sub_name()"} = {};
    }
    while ($block_in =~ /&((\w+::)*\w+)\(/gms) {
      &counted_set::add($$ds{$pkg}{'*sub*'}{"$sub_name()"}, "$1()");
    }
  }
}
#print &Dumper($ds);

sub pkg_from_path
{
  my ($path) = @_;
  my $pkg = $path;
  $pkg =~ s|^../lib/||;
  $pkg =~ s|\.pm$||;
  $pkg =~ s|/|::|g;
  return $pkg;
}

my $nodes = {};
my $edges = {};
foreach my $pkg (keys %$ds) {
  my $label = '';
  my $d = "\"";
  while (my ($defn, $dependency) = each %{$$ds{$pkg}{'*sub*'}}) {
    $label .= "$d\{<$defn> $defn\}";
    $d = '|';
    $$edges{$pkg}{$defn} = $dependency;
  }
  $label .= "\"";
  $$nodes{$pkg}{'label'} = $label;
}
#print &Dumper($nodes);
#print &Dumper($edges);

my $node_lines = [];
foreach my $pkg (keys %$nodes) {
  my $d = '';
  my $line = "\"$pkg\" [ ";
  while (my ($attr_key, $attr_val) = each %{$$nodes{$pkg}}) {
    my $attr_val = $$nodes{$pkg}{$attr_key};
    $line .= "$d$attr_key = $attr_val";
    $d = ", ";
  }
  $line .= " ];\n";
  push @$node_lines, $line;
}
my $edge_lines = [];
foreach my $pkg (keys %$edges) {
  while (my ($defn, $dependency) = each %{$$edges{$pkg}}) {
    while (my ($sub, $count) = each %$dependency) {
      my $line = "\"$pkg\":\"$defn\" -> \"$sub\";\n";
      push @$edge_lines, $line;
    }
  }
}

print
  "digraph module-symbols-dependencies {\n" .
  "  graph [ label = \"\\G\", fontcolor = red ];\n" .
  "  graph [ rankdir = \"LR\",\n" .
  "          center = true,\n" .
  "          size = \"7.5,10\" ];\n" .
  "\n" .
  "  node [ shape = \"record\" ];\n" .
  "\n";

print "@$node_lines";
print "@$edge_lines";

print "\n}\n";
