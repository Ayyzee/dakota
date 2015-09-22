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
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1;   # default = 2

my $fh;
open($fh, "<", "/usr/share/dict/words") or die;

my $count_from_length = [];

while (<$fh>) {
    chomp();
    my $len = length($_);
    if (!defined $$count_from_length[$len]) {
        $$count_from_length[$len] = 0;
    }
    $$count_from_length[$len]++;
}
#shift @$count_from_length;
#print &Dumper($count_from_length);

my $total_count = 0;
my $total_lens = 0;

for (my $i = 1; $i < scalar @$count_from_length; $i++) {
    $total_count += $$count_from_length[$i];
    $total_lens += $i * $$count_from_length[$i];
    printf("% 3i: % 6i\n", $i, $$count_from_length[$i]);
}
printf("ave: %.1f\n", $total_lens/$total_count);
