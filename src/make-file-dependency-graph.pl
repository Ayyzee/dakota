#!/usr/bin/perl

use strict;
use warnings;

my $name = `../bin/dakota-project --repository dakota-project.rep --var SO_EXT=dylib name`;
chomp $name;
my $dk_files = [split("\n", `../bin/dakota-project --repository dakota-project.rep files`)];
#my $dk_files = [ "object.dk", "klass.dk", "exception.dk", "table.dk", "set.dk" ];

my $rt_nodes = [];
my $nrt_rep_files = {};
my $o_files = [];
my $edges = [];
my $gen_src_nodes = [];

my $bname = $name; $bname =~ s/\.dylib$//;
my $rt_rep_file = "obj/rt/lib$bname.rep";
my $rt_hxx_file = "obj/rt/lib$bname.hh";
my $rt_cxx_file = "obj/rt/lib$bname.cc";
my $rt_o_file =   "obj/rt/lib$bname.o";
my $rt_so_file =  "obj/rt/lib$bname.dylib";

push @$gen_src_nodes, ($rt_hxx_file,
                       $rt_cxx_file);

push @$rt_nodes, ($rt_rep_file,
                  $rt_hxx_file,
                  $rt_cxx_file,
                  $rt_o_file,
                  $rt_so_file);

foreach my $dk_file (@$dk_files) {
  chomp $dk_file;
  my $bfile = $dk_file; $bfile =~ s/\.dk$//;

  my $nrt_rep_file = "obj/$dk_file.rep";
  my $dk_cxx_file =  "obj/$dk_file.cc";
  my $nrt_hxx_file = "obj/nrt/$bfile.hh";
  my $nrt_cxx_file = "obj/nrt/$bfile.cc";
  my $nrt_o_file =   "obj/nrt/$bfile.o";

  $$nrt_rep_files{$nrt_rep_file} = 1;
  push @$o_files,   $nrt_o_file;

  push @$gen_src_nodes, ($nrt_hxx_file,
                         $nrt_cxx_file);

  push @$edges, [ $dk_cxx_file,  $nrt_rep_file ];
  push @$edges, [ $dk_cxx_file,  $dk_file ];
  push @$edges, [ $rt_rep_file,  $dk_file ];
  push @$edges, [ $nrt_o_file,   $dk_cxx_file ];

  push @$edges, [ $nrt_rep_file, $dk_file ];

  push @$edges, [ $nrt_hxx_file, $nrt_rep_file ];
  push @$edges, [ $nrt_cxx_file, $nrt_rep_file ];
  push @$edges, [ $nrt_o_file,   $nrt_hxx_file ];
  push @$edges, [ $nrt_o_file,   $nrt_cxx_file ];
}

foreach my $nrt_rep_file (sort keys %$nrt_rep_files) {
    push @$edges, [ $nrt_rep_file, $rt_rep_file ];
}
foreach my $o_file (@$o_files) {
    push @$edges, [ $rt_so_file, $o_file ];
}

push @$edges, [ $rt_hxx_file, $rt_rep_file ];
push @$edges, [ $rt_cxx_file, $rt_rep_file ];
push @$edges, [ $rt_o_file,   $rt_hxx_file ];
push @$edges, [ $rt_o_file,   $rt_cxx_file ];

push @$edges, [ $rt_so_file,  $rt_o_file ];

print "digraph {\n";
print "  graph [ rankdir = RL, center = true, page = \"8.5,11\", size = \"7.5,10\" ];";
print "  node  [ shape = rect, style = rounded ];\n";
foreach my $rt_node (@$rt_nodes) {
  print "  \"$rt_node\" [ color = blue ];\n";
}
foreach my $edge (@$edges) {
  print "  \"$$edge[0]\" -> \"$$edge[1]\"";
  if ($$nrt_rep_files{$$edge[0]} && $rt_rep_file eq $$edge[1]) {
    print " [ style = dotted ]";
  }
  print ";\n"
}
print "  { rank = same";
foreach my $gen_src_node (@$gen_src_nodes) {
  print "; \"$gen_src_node\"";
}
print " }\n";
print "}\n";
