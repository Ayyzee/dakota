#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1;   # default = 2

my $patterns = {
  'cc-path-from-dk-path' =>       '$(objdir)/nrt/%.$(cc_ext)  : %.dk',
  'cc-path-from-so-path' =>       '$(objdir)/rt/%.$(cc_ext)   : %.$(so_ext)',
  'ctlg-dir-path-from-so-path' => '$(objdir)/%                : %.$(so_ext)',
  'ctlg-path-from-so-path' =>     '$(objdir)/%.$(so_ext).ctlg : %.$(so_ext)',
  'o-path-from-cc-path' =>        '$(objdir)/%.$(o_ext)       : $(objdir)/%.$(cc_ext)',
  'o-path-from-dk-path' =>        '$(objdir)/nrt/%.$(o_ext)   : %.dk',
  'rep-path-from-ctlg-path' =>    '$(objdir)/%.ctlg.rep       : $(objdir)/%.ctlg',
  'rep-path-from-dk-path' =>      '$(objdir)/%.dk.rep         : %.dk',
  'rep-path-from-so-path' =>      '$(objdir)/%.rep            : %.$(so_ext)',
};
my $expanded_patterns;
sub expanded_patterns {
  if (!$expanded_patterns) {
    $expanded_patterns = &expand_tbl_values($patterns, {});
  }
  return $expanded_patterns;
}

my $so_ext = 'so';
my $cc_ext = 'cc';
my $o_ext =  'o';
my $objdir = 'obj';

BEGIN {
};

sub expand {
  my ($str) = @_;
  $str =~ s/(\$\w+)/$1/eeg;
  #$str =~ s/(\$\w+)/$1/eg;
  return $str;
}
sub expand_tbl_values {
  my ($tbl_in, $tbl_out) = @_;
  if (!$tbl_out) {
    $tbl_out = {};
  }
  my ($key, $val);

  while (($key, $val) = each (%$tbl_in)) {
    $val = &expand(&var_perl_from_make($val));
    $$tbl_out{$key} = $val;
  }
  #print &Dumper($tbl_out);
  return $tbl_out;
}
sub rel_path_canon {
  my ($path) = @_;
  my $result = $path;
  ###
  return $result;
}
sub start {
  my ($argv) = @_;
  my $pattern_name = 'rep-path-from-so-path';
  my $path_in = 'foo/bar.$(so_ext)';
  print 'pattern-name: ' . $pattern_name . "\n";
  print 'in:  ' . $path_in . "\n";
  my $path_out = &out_path_from_in_path($pattern_name, $path_in);
  print 'out: ' . $path_out . "\n";
}
sub var_perl_from_make { # convert variable syntax to perl from make
  my ($str) = @_;
  my $result = $str;
  $result =~ s|\$\((\w+)\)|\$$1|g;
  $result =~ s|\$\{(\w+)\}|\$$1|g;
  return $result;
}
sub rep_path_from_so_path {
  my ($in_path) = @_;
  return &out_path_from_in_path('rep-path-from-so-path', $in_path);
}
sub out_path_from_in_path {
  my ($pattern_name, $path_in) = @_;
  #my $pattern = $$patterns{$pattern_name} =~ s|\s*:\s*| : |r;
  #print 'pattern: ' . $pattern . "\n";
  $expanded_patterns = &expanded_patterns();
  my $pattern = $$expanded_patterns{$pattern_name} =~ s|\s*:\s*| : |r;
  print 'pattern: ' . $pattern . "\n";
  my $result = &expand(&var_perl_from_make($path_in));
  print 'in:  ' . $result . "\n";
  my ($pattern_replacement, $pattern_template) = split(/\s*:\s*/, $pattern);
  $pattern_template =~ s|\%|(\.+?)|;

 #$pattern_replacement =~ s|\%|&rel_path_canon(\$1)|;
 #$pattern_replacement =~ s|\%|\$1|;
 #$pattern_replacement =~ s|\%|&rel_path_canon(\%s)|;
  $pattern_replacement =~ s|\%|\%s|;

 #print STDERR "DEBUG: $pattern_template  ->  $pattern_replacement\n";
 #print STDERR "DEBUG: $path_in\n";

  if (1) {
    if ($result =~ m|^$pattern_template$|) {
      $result = sprintf($pattern_replacement, &rel_path_canon($1));
      $result = &expand($result);
    }
  } else {
    #my $result0 = $path_in =~ s|^(.+?)\.so$|obj/$1.rep|r;
    #print "DEBUG: result0:  $result0\n";

    $pattern_replacement =~ s|\%s|\$1|;
    $result = $path_in =~ s|^$pattern_template$|$pattern_replacement|r;
  }
  return $result;
}

unless (caller) {
  &start(\@ARGV);
}
