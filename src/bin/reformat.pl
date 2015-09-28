#!/usr/bin/perl -w -i

use strict;
use warnings;

$main::list = qr{
                  \(
                  (?:
                    (?> [^()]+ )         # Non-parens without backtracking
                  |
                    (??{ $main::list }) # Group with matching parens
                  )*
                  \)
              }x;

undef $/;

#local $^I   = '.orig';              # emulate  -i.orig
#local @ARGV = glob("*.dk");          # initialize list of files

while (<>) {
  # all transform blah // comments to blah { // comments
  while (s^\n(\s*)(else-if|if|for|while)\s*($main::list)\s*?(\s//.*?)?\n\s*\{\s*\n^\n$1$2 $3 \{$4\n^gm) {}
  while (s^\n(\s*)do\s*?(//.*?)?\n\s*\{\s*\n^\n$1do \{$2\n^gm) {}
  while (s^\n(\s*)\}\s*\n\s*else\s*\n\s*\{\s*?(\s//.*?)?\n^\n$1\} else \{$2\n^gm) {}
  print;
} continue {close ARGV if eof}
