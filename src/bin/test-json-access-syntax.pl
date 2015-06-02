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
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = 1;

# 'seq[3].z[1]'
# =>
# '{seq}[3]{z}[1]'

# 'tbl.c'
# =>
# '{tbl}{c}';

# 'seq[1]'
# =>
# '{seq}[1]'

# 'tbl.b'
# =>
# '{tbl}{b}

my $data;

if (1) {
    $data = { 'seq' => [ 'a', 'b', 'c', { 'x' => 'X',
                                          'y' => 'Y',
                                          'z' => [ 8, 16, 32 ] }
                  ],
              'tbl' => { 'a' => 'A',
                         'b' => 'B',
                         'c' => 'C' }
    };
} else {
    $data = do $ARGV[0] or die;
}

my $cmd1 = $ARGV[1];
my $cmd2 = sprintf('$$data%s', $cmd1);
my $result = eval $cmd2 or die;
print $result . " # $cmd2\n";
