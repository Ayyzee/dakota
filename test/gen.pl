#!/usr/bin/perl -w

use strict;

my ($dir, $output);
if (1 == @ARGV)
{ $dir = $ARGV[0]; $output = undef; }
elsif (2 == @ARGV)
{ $dir = $ARGV[0]; $output = $ARGV[1]; }
else
{ die; }

my $exe_paths = [ glob "$dir/*/exe\.{dk,cc}" ];
my $lib_paths = [ glob "$dir/*/lib-*\.{dk,cc}" ];

my $all = &start($exe_paths, $lib_paths);
#print &Dumper($all);
&generate_all($all, $output);

sub start
{
    my ($exe_paths, $lib_paths) = @_;
    my $all = {};

    foreach my $path (@$exe_paths) {
	my $exe_path = &exe_path_from_src_path($path);
	$$all{$exe_path}{$path} = 1;
	my $dir = &dir_part($path);
    }
    foreach my $path (@$lib_paths) {
	my $exe_path = &exe_path_from_src_path($path);
	my $so_path =  &so_path_from_src_path($path);
	$$all{$exe_path}{$so_path} = 1;
	$$all{$so_path}{$path} = 1;
    }
    return $all;
}

sub dir_part
{
    my ($path) = @_;
    my $result = $path;
    $result =~ s|(.*)(/.*)|$1|;
    return $result;
}

sub generate_all
{
    my ($all, $output) = @_;
    my $str;
    $str = '';
    foreach my $target (sort keys %$all) {
	if (&is_exe($target)) {
	    $str .= "$target\n";
	}
    }
    print $str;
    $str = '';
    foreach my $target (sort keys %$all) {
	my $depends = $$all{$target};
	$str .= "$target:";
	foreach my $depend (sort keys %$depends) {
	    $str .= "\\\n$depend";
	}
	$str .= "\n\n";
    }
    if ($output) {
	open FILE, ">$output" || "$output: $!\n";
	print FILE $str;
	close FILE;
    }
    else {
	print $str;
    }
}

sub is_exe
{
    my ($path) = @_;

    if ($path =~ m/exe$/)
    { return 1; }
    else
    { return 0; }
}

sub exe_path_from_src_path
{
    my ($src_path) = @_;
    my $exe_path = $src_path;
    $exe_path =~ s/exe\.(dk|cc)$/exe/;
    $exe_path =~ s/lib-(\d)-\d\.(dk|cc)$/exe/;
    $exe_path =~ s/lib-(\d)\.(dk|cc)$/exe/;
    return $exe_path;
}

sub so_path_from_src_path
{
    my ($src_path) = @_;
    my $so_path = $src_path;
    $so_path =~ s/lib-(\d)-\d\.(dk|cc)$/lib-$1.\$(SO_EXT)/;
    $so_path =~ s/lib-(\d)\.(dk|cc)$/lib-$1.\$(SO_EXT)/;
    return $so_path;
}
