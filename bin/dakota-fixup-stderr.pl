#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

my $prefix;

BEGIN {
  $prefix = '/usr/local';
  if ($ENV{'DK_PREFIX'}) {
    $prefix = $ENV{'DK_PREFIX'};
  }
  unshift @INC, "$prefix/lib";
};

use dakota::util;

my $gbl_cwd = $ARGV[0] ||= '\*\*NO-CWD\*\*';
my $gbl_parent = $ARGV[1] ||= '\*\*NO-PARENT\*\*';

my $name_re = qr{[\w.=+-]+};
my $rel_dir_re = qr{$name_re/+};
my $path_re = qr{/*$rel_dir_re*?$name_re/*};

sub fixup {
  my ($cwd, $parent, $file, $line) = @_;
  $cwd = &dakota::util::canon_path($cwd);
  $parent = &dakota::util::canon_path($parent);
  $cwd =~ s|/+$parent$||;

  if (-e "$cwd/$parent/$file") {
    my $path = "$parent/$file";
    $path = &dakota::util::canon_path($path);
    return "$path:$line:";
  } else {
    return "$file:$line:";
  }
}

while (<STDIN>) {
  my $line = $_;
  $line =~ s|^\s*[Ii]n file included from.+?:\d+:\s*$||;
  $line =~ s|($path_re):(\d+):|&fixup($gbl_cwd, $gbl_parent, $1, $2)|eg;
  print $line;
}
