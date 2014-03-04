#!/usr/bin/perl -w

use strict;
undef $/;

my $k  = qr/[_A-Za-z0-9-]+/; # dakota identifier

my $klasses = {};
my $path;

foreach $path (@ARGV)
{
    my $filestr = &string_from_file($path);

    $filestr =~ s|\#include(\s+".*?")|import$1;|g;
    $filestr =~ s|\#include(\s+<.*?>)|import$1;|g;

    $filestr =~ s|\binclude(\s+".*?")|export$1|g;
    $filestr =~ s|\binclude(\s+<.*?>)|export$1|g;

    &string_to_file($filestr, $path);
}

sub string_from_file
{
    my ($file) = @_;
    open(FILE, "<$file") or die(__FILE__, ":", __LINE__, ": ERROR: $file: $!\n");
    my $string = <FILE>;
    close(FILE);
    return $string;
}

sub string_to_file
{
    my ($string, $file) = @_;
    open(FILE, ">$file") or die(__FILE__, ":", __LINE__, ": ERROR: $file: $!\n");
    print FILE $string;
    close(FILE) or die(__FILE__, ":", __LINE__, ": ERROR: $file: $!\n");
    return;
}
