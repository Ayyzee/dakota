#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $src_name =          "stdin-src.dk";
my $src_comments_name = "stdin-src-comments.dk";
my $tbl = { 'src' => '', 'src-comments' => '' };
undef $/;
my $in = <STDIN>;
&tear($in, $tbl);

open(my $src, ">", $src_name) or die $!;
print $src $$tbl{'src'};
close $src;
open(my $src_comments, ">", $src_comments_name) or die $!;
print $src_comments $$tbl{'src-comments'};
close $src_comments;

my $out = &mend($tbl);
print $out;

sub tear {
  my ($filestr, $tbl) = @_;
  foreach my $line (split /\n/, $filestr) {
    if ($line =~ m|^(.*?)(\s*//.*)?$|m) {
      $$tbl{'src'} .= $1 . "\n";
      if ($2) {
        $$tbl{'src-comments'} .= $2;
      }
      $$tbl{'src-comments'} .= "\n";
    } else {
      die $line $!;
    }
  }
}
sub mend {
  my ($tbl) = @_;
  my $result = '';
  my $src_lines = [split /\n/, $$tbl{'src'}];
  my $src_comment_lines = [split /\n/, $$tbl{'src-comments'}];
  die if scalar(@$src_lines) != scalar(@$src_comment_lines);
  for (my $i = 0; $i < scalar(@$src_lines); $i++) {
    my $src_line = $$src_lines[$i];
    my $src_comment_line = $$src_comment_lines[$i];
    $result .= $src_line . $src_comment_line . "\n";
  }
  return $result;
}
