#!/usr/bin/perl

use strict;
use warnings;

die "Too many args." if @ARGV > 1;

my $project_file = 'dummy-project.rep';

if (@ARGV == 1) {
  $project_file = $ARGV[0];
}

my $SO_EXT = 'dylib';

my $name = `../bin/dakota-project name --repository $project_file --var SO_EXT=$SO_EXT`;
chomp $name;

my $so_files = [split("\n", `../bin/dakota-project libs --repository $project_file --var SO_EXT=$SO_EXT`)];
my $dk_files = [split("\n", `../bin/dakota-project srcs --repository $project_file`)];

my $input_files = [ @$so_files, @$dk_files ];

my $nrt_rep_files = {};
my $o_files = {};
my $edges = [];
my $nrt_src_files = {};
my $dk_cxx_files = {};

my $bname = $name; $bname =~ s/\.$SO_EXT$//;
my $rt_rep_file = "obj/rt/lib$bname.rep";
my $rt_hxx_file = "obj/rt/lib$bname.hh";
my $rt_cxx_file = "obj/rt/lib$bname.cc";
my $rt_o_file =   "obj/rt/lib$bname.o";
my $rt_so_file =  "obj/rt/lib$bname.$SO_EXT";

my $rt_files = { $rt_hxx_file => 1,
                 $rt_cxx_file => 1 };

foreach my $so_file (@$so_files) {
  my $ctlg_file = "$so_file.ctlg";
  my $rep_file = "$ctlg_file.rep";

  push @$edges, [ $ctlg_file,   $so_file ];
  push @$edges, [ $rep_file,    $ctlg_file ];
  push @$edges, [ $rt_rep_file, $rep_file ];
}

foreach my $dk_file (@$dk_files) {
  my $bfile = $dk_file; $bfile =~ s/\.dk$//;

  my $nrt_rep_file = "obj/$dk_file.rep";
  my $dk_cxx_file =  "obj/$dk_file.cc";
  my $nrt_hxx_file = "obj/nrt/$bfile.hh";
  my $nrt_cxx_file = "obj/nrt/$bfile.cc";
  my $nrt_o_file =   "obj/nrt/$bfile.o";

  $$dk_cxx_files{$dk_cxx_file} = 1;

  $$nrt_src_files{$dk_cxx_file} = 1;
  $$nrt_src_files{$nrt_hxx_file} = 1;
  $$nrt_src_files{$nrt_cxx_file} = 1;

  $$nrt_rep_files{$nrt_rep_file} = 1;
  $$o_files{$nrt_o_file} = 1;

  push @$edges, [ $nrt_rep_file, $dk_file ];
  push @$edges, [ $dk_cxx_file,  $dk_file ];
  push @$edges, [ $dk_cxx_file,  $rt_rep_file ];
  push @$edges, [ $nrt_o_file,   $dk_cxx_file ];

  push @$edges, [ $nrt_hxx_file, $rt_rep_file ];
  push @$edges, [ $nrt_cxx_file, $rt_rep_file ];

  push @$edges, [ $nrt_hxx_file, $nrt_rep_file ];
  push @$edges, [ $nrt_cxx_file, $nrt_rep_file ];
  push @$edges, [ $nrt_o_file,   $nrt_hxx_file ];
  push @$edges, [ $nrt_o_file,   $nrt_cxx_file ];
}
push @$edges, [ $rt_hxx_file, $rt_rep_file ];
push @$edges, [ $rt_cxx_file, $rt_rep_file ];
push @$edges, [ $rt_o_file,   $rt_hxx_file ];
push @$edges, [ $rt_o_file,   $rt_cxx_file ];

foreach my $o_file (sort keys %$o_files) {
  push @$edges, [ $rt_so_file, $o_file ];
}
push @$edges, [ $rt_so_file, $rt_o_file ];

foreach my $nrt_rep_file (sort keys %$nrt_rep_files) {
  push @$edges, [ $rt_rep_file, $nrt_rep_file ];
}
print
  "digraph {\n" .
  "  graph [ rankdir = RL, center = true, page = \"8.5,11\", size = \"7.5,10\" ];\n" .
  "  edge  [ ];\n" .
  "  node  [ shape = rect, style = rounded, height = 0.25 ];\n" .
  "\n";
foreach my $so_file (sort @$so_files) {
  print "  \"$so_file\" [ color = green ];\n";
}
print "\n";
foreach my $rt_file (sort keys %$rt_files) {
  print "  \"$rt_file\" [ color = blue ];\n";
}
print "\n";
foreach my $dk_cxx_file (sort keys %$dk_cxx_files) {
  print "  \"$dk_cxx_file\" [ color = orange ];\n";
}
print "\n";
foreach my $edge (sort @$edges) {
  print "  \"$$edge[0]\" -> \"$$edge[1]\"";
  if ($$nrt_src_files{$$edge[0]} && $rt_rep_file eq $$edge[1]) {
    print " [ style = dotted ]";
  }
  print ";\n"
}
if (1) {
  print "  { rank = same";
  foreach my $input_file (sort @$input_files) {
    print "; \"$input_file\"";
  }
  print "; }\n";
}
print "}\n";
