#!/usr/bin/perl -w

use strict;
use warnings;

my $dquoted_str = qr/(?<!\\)".*?(?<!\\)"/;
my $squoted_str = qr/(?<!\\)'.*?(?<!\\)'/;

sub newlines {
  my ($str) = @_;
  if ($str =~ m/^"/) {
    $str = '""';
  } elsif ($str =~ m/^'/) {
    $str = "''";
  } else {
    $str =~ s|[^\n]+||gs;
  }
  return $str;
}

undef $/;
my $filestr = <STDIN>;

$filestr =~ s=(//.*?\n|/\*.*?\*/|$dquoted_str|$squoted_str)=newlines($1)=egs;
$filestr =~ s=^(\s*\#\s*include\s*)<(.+?)>=$1<>=gm;







print $filestr;
