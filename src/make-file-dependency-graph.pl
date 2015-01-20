#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

die "Too many args." if @ARGV > 1;

my $project_file = 'dummy-project.rep';

if (@ARGV == 1) {
  $project_file = $ARGV[0];
}

sub rdir_name_ext {
  my ($path) = @_;
  $path =~ m|^/?((.+)/)?(.*?)\.(.*)$|;
  my ($rdir, $name, $ext) = ($2, $3, $4);
  die "Error parsing path '$path'" if !$name;
  return ($rdir ||= '', $name, $ext ||= '');
}

my $SO_EXT = 'dylib';
my $colorscheme = 'dark26'; # needs to have 5 or more colors
my $show_headers = 0;

my $result = `../bin/dakota-project name --repository $project_file --var SO_EXT=$SO_EXT`;
chomp $result;

my $so_files = [split("\n", `../bin/dakota-project libs --repository $project_file --var SO_EXT=$SO_EXT`)];
my $dk_files = [split("\n", `../bin/dakota-project srcs --repository $project_file`)];

my $input_files = [ @$so_files, @$dk_files ];

my $nrt_rep_files = {};
my $o_files = {};
my $edges = [];
my $nrt_src_files = {};
my $dk_cc_files = {};

my $obj = 'obj';

my ($rdir, $name, $ext) = &rdir_name_ext($result);
my $rt_rep_file = "$obj/rt/$name.rep";
my $rt_hh_file =  "$obj/rt/$name.hh";
my $rt_cc_file =  "$obj/rt/$name.cc";
my $rt_o_file =   "$obj/rt/$name.o";

my $rt_files = {};

if ($show_headers) {
    $$rt_files{$rt_hh_file} = undef;
}
$$rt_files{$rt_cc_file} = undef;

foreach my $so_file (@$so_files) {
  my ($rdir, $name, $ext) = &rdir_name_ext($so_file);
  my $ctlg_file = "$obj/$rdir/$name.ctlg";
  my $rep_file =  "$obj/$rdir/$name.rep";

  push @$edges, [ $ctlg_file,   $so_file,   1 ];
  push @$edges, [ $rep_file,    $ctlg_file, 2 ];
  push @$edges, [ $rt_rep_file, $rep_file,  3 ];
}
foreach my $dk_file (@$dk_files) {
  my ($rdir, $name, $ext) = &rdir_name_ext($dk_file);
  my $nrt_rep_file = "$obj/$rdir/$name.rep";
  my $dk_cc_file =   "$obj/$rdir/$name.cc";
  my $nrt_hh_file =  "$obj/nrt/$rdir/$name.hh";
  my $nrt_cc_file =  "$obj/nrt/$rdir/$name.cc";
  my $nrt_o_file =   "$obj/nrt/$rdir/$name.o";

  $$dk_cc_files{$dk_cc_file} = undef;

  $$nrt_src_files{$dk_cc_file} = undef;
  if ($show_headers) {
    $$nrt_src_files{$nrt_hh_file} = undef;
  }
  $$nrt_src_files{$nrt_cc_file} = undef;

  $$nrt_rep_files{$nrt_rep_file} = undef;
  $$o_files{$nrt_o_file} = undef;

  push @$edges, [ $nrt_rep_file, $dk_file,    1 ];
  push @$edges, [ $dk_cc_file,  $dk_file,     4 ];
  push @$edges, [ $dk_cc_file,  $rt_rep_file, 0 ]; # gray, dashed
  push @$edges, [ $nrt_o_file,   $dk_cc_file, 5 ];

  if ($show_headers) {
    push @$edges, [ $nrt_hh_file, $rt_rep_file, 0 ]; # gray, dashed
    push @$edges, [ $nrt_hh_file, $nrt_rep_file, 4 ];
    push @$edges, [ $nrt_o_file,   $nrt_hh_file, 5 ];
  }

  push @$edges, [ $nrt_cc_file, $rt_rep_file, 0 ]; # gray, dashed

  push @$edges, [ $nrt_cc_file, $nrt_rep_file, 4 ];
  push @$edges, [ $nrt_o_file,   $nrt_cc_file, 5 ];
}
foreach my $nrt_rep_file (sort keys %$nrt_rep_files) {
  push @$edges, [ $rt_rep_file, $nrt_rep_file, 3 ];
}
if ($show_headers) {
    push @$edges, [ $rt_hh_file, $rt_rep_file, 4 ];
    push @$edges, [ $rt_o_file,   $rt_hh_file, 5 ];
}

push @$edges, [ $rt_cc_file, $rt_rep_file, 4 ];
push @$edges, [ $rt_o_file,   $rt_cc_file, 5 ];

foreach my $o_file (sort keys %$o_files) {
  push @$edges, [ $result, $o_file, 0 ]; # black indicates no concurrency (linking)
}
push @$edges, [ $result, $rt_o_file, 0 ]; # black indicates no concurrency (linking)
print
  "digraph {\n" .
  "  graph [ rankdir = RL, center = true, page = \"8.5,11\", size = \"7.5,10\" ];\n" .
  "  edge  [ ];\n" .
  "  node  [ shape = rect, style = rounded, height = 0.25 ];\n" .
  "\n" .
  "  \"$result\" [ style = none ];\n" .
  "\n";
if ($show_headers) {
  print "  \"$rt_hh_file\" [ colorscheme = $colorscheme, color = 4 ];\n";
}
print "  \"$rt_cc_file\" [ colorscheme = $colorscheme, color = 4 ];\n";
print "\n";

foreach my $so_file (sort @$so_files) {
  print "  \"$so_file\" [ style = none ];\n";
}
print "\n";
foreach my $dk_cc_file (sort keys %$dk_cc_files) {
  print "  \"$dk_cc_file\" [ style = \"rounded,bold\" ];\n";
}
print "\n";
foreach my $edge (sort @$edges) {
  print "  \"$$edge[0]\" -> \"$$edge[1]\"";
  if (exists $$nrt_src_files{$$edge[0]} && $rt_rep_file eq $$edge[1]) {
    print " [ style = dashed, color = gray ]";
  } elsif ($$edge[2]) {
    print " [ colorscheme = $colorscheme, color = $$edge[2] ]";
  }
  print ";\n"
}
print
  "\n" .
  "  subgraph {\n" .
  "    rank = same;\n" .
  "\n";
foreach my $input_file (sort @$input_files) {
  print "    \"$input_file\";\n";
}
print "  }\n";
print "}\n";
