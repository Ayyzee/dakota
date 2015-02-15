#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;
use File::Spec;
use Cwd;

my $name_re = qr{[\w.=+-]+};
my $rel_dir_re = qr{$name_re/+};
my $path_re = qr{/*$rel_dir_re*?$name_re/*};

sub fixup {
  my ($initial_workdir, $file, $line_num) = @_;
  $initial_workdir = File::Spec->canonpath($initial_workdir);
  my $current_workdir = &getcwd();
  my $reldir = File::Spec->abs2rel($current_workdir, $initial_workdir);
  if (0) {
    print STDERR
      "INITIAL_WORKDIR: $initial_workdir\n" .
      "CURRENT_WORKDIR: $current_workdir\n" .
      "RELDIR:          $reldir\n" .
      "RELDIR/FILE:     $reldir/$file\n";
  }
  if (-e "$initial_workdir/$reldir/$file") {
    return "$reldir/$file:$line_num:";
  } else {
    return "$file:$line_num:";
  }
}

my $initial_workdir = $ARGV[0] ||= undef;

while (<STDIN>) {
  my $line = $_;
  $line =~ s|^\s*[Ii]n file included from.+?:\d+:\s*$||;
  if ($initial_workdir) {
    $line =~ s|($path_re):(\d+):|&fixup($initial_workdir, $1, $2)|eg;
  }
  print $line;
}
