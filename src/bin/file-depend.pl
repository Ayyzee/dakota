#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $patterns = {
  #'rep-from-so' => '$(objdir)/%.rep : %.$(so_ext)',
  'rep-from-so' => '$(objdir)/%.rep : %.so',
};
my $so_ext = 'so';
my $objdir = 'obj';

sub canon_path {
  my ($path) = @_;
  my $result = $path;
  ###
  return $result;
}

# pattern       '$(objdir)/%.rep  :  %.$(so_ext)'
# regex     s|  ^(.+?)\.$so_ext$  |  $objdir/$1\.rep |
sub start {
  my ($argv) = @_;
  my $pattern = $$patterns{'rep-from-so'};
  #my $xx_path = 'foo/bar.$(so_ext)';
  my $xx_path = 'foo/bar.so';
  print 'pattern: ' . $pattern . "\n";
  print 'in:  ' . $xx_path . "\n";
  my $yy_path = &yy_path_from_xx_path($pattern, $xx_path);
  print 'out: ' . $yy_path . "\n";
}

sub var_make_to_perl { # convert variable syntax from make to perl
  my ($str) = @_;
  my $result = $str;
  $result =~ s|\$\((\w+)\)|\$$1|g;
  return $result;
}
sub escape {
  my ($str, $tbl) = @_;
  my $result = $str;
  my ($key, $val);

  while (($key, $val) = each (%$tbl)) {
    $result =~ s|$key|$val|g;
  }
  return $result;
}
sub yy_path_from_xx_path {
  my ($pattern_make, $xx_path_make) = @_;
  my $pattern = &var_make_to_perl($pattern_make);
  my $xx_path = &var_make_to_perl($xx_path_make);

  my ($pattern_replacement, $pattern_template) = split(/\s*:\s*/, $pattern);
  my $tbl = {
    '\.'=>     '\\.',
    #'\$' => '\\$',
  };
  $pattern_template =    &escape($pattern_template,    $tbl);
  $pattern_template =~    s|\%|(\.+?)|;
  #$pattern_replacement =~ s|\%|&canon_path(\$1)|;

  #$pattern_replacement =~ s|\%|\$1|;
  $pattern_replacement =~ s|\%|\%s|;

  #$pattern_template =     qr/$pattern_template/;
  #$pattern_replacement =  qr/$pattern_replacement/;

  my $result = $xx_path;

  if (1) {
    if ($result =~ m|^$pattern_template$|) {
      $result = sprintf($pattern_replacement, $1);
    }
  } else {
    #my $result0 = $xx_path =~ s|^(.+?)\.$so_ext$|$objdir/$1.rep|r;
    #print "  result0:  $result0\n";

    $pattern_replacement =~ s|\%s|%|;
    $result = $xx_path =~ s|^$pattern_template$|$pattern_replacement|r;
  }
  return $result;
}

unless (caller) {
  &start(\@ARGV);
}
