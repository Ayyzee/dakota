#!/usr/bin/perl -w

use strict;

undef $/;
my $filestr = <STDIN>;
use Text::Markdown 'markdown';

my $html = markdown($filestr);
print $html;
