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
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1;   # default = 2

my $obj = 'obj';
my $SO_EXT = 'dylib';
my $colorscheme = 'dark26';     # needs to have 5 or more colors
my $show_headers = 0;
my $keyword = { 'graph' => 1, 'edge' => 1, 'node' => 1 };

my $gbl_col_width = '  ';
sub colin {
  my ($col) = @_;
  my $len = length($col)/length($gbl_col_width);
  #print STDERR "$len" . "++\n";
  $len++;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub colout {
  my ($col) = @_;
  my $len = length($col)/length($gbl_col_width);
  die "Aborted because of &colout(0)" if '' eq $col;
  $len--;
  my $result = $gbl_col_width x $len;
  return $result;
}
sub path {
  my ($path) = @_;
  $path =~ s|//|/|g;
  $path =~ s|/\./|/|g;
  $path =~ s|^\./||g;
  $path =~ s|/$||g;
  return $path;
}
sub rdir_name_ext {
  my ($path) = @_;
  $path =~ m|^/?((.+)/)?(.*?)\.(.*)$|;
  my ($rdir, $name, $ext) = ($2, $3, $4);
  die "Error parsing path '$path'" if !$name || !$ext;;
  return ($rdir ||= '.', $name, $ext);
}
sub add_node {
  my ($tbl, $n, $attrs) = @_;
  if (!exists $$tbl{'nodes'}{$n}) {
    $$tbl{'nodes'}{$n} = $attrs;
  } else {
    my ($key, $val);
    while (($key, $val) = each (%$attrs)) {
      $$tbl{'nodes'}{$n}{$key} = $val;
    }
  }
}
sub add_edge {
  my ($tbl, $n1, $n2, $attrs) = @_;

  if (!exists $$tbl{'edges'}{$n1}) {
    $$tbl{'edges'}{$n1} = undef;
  }
  if (!exists $$tbl{'edges'}{$n1}{$n2}) {
    $$tbl{'edges'}{$n1}{$n2} = $attrs;
  } else {
    my ($key, $val);
    while (($key, $val) = each (%$attrs)) {
      $$tbl{'edges'}{$n1}{$n2}{$key} = $val;
    }
  }
}
sub add_subgraph {
  my ($tbl, $subgraph) = @_;
  if (!$$tbl{'subgraphs'}) {
    $$tbl{'subgraphs'} = [];
  }
  $$subgraph{'type'} = 'subgraph';
  push @{$$tbl{'subgraphs'}}, $subgraph;
}
sub str4attrs {
  my ($attrs) = @_;
  my $str = '';
  if ($attrs) {
    my $d = '';
    $str .= " \[";
    foreach my $key (sort keys %$attrs) {
      my $val = $$attrs{$key};
      if ($val =~ /^(\d|\w)+$/) {
        $str .= "$d $key = $val";
      } else {
        $str .= "$d $key = \"$val\"";
      }
      $d = ',';
    }
    $str .= " ]";
  }
  return $str;
}
sub str4node {
  my ($node) = @_;
  my $str;
  if ($node) {
    if ($node =~ /^(\d|\w)+$/) {
      $str = "$node";
    } else {
      $str = "\"$node\"";
    }
  }
  return $str;
}
sub strln4node {
  my ($node, $attrs, $col) = @_;
  my $str = '';
  if ($node) {
    $str .= $col . &str4node($node);
    $str .= &str4attrs($attrs);
    $str .= ";\n";
  }
  return $str;
}
sub strln4edge {
  my ($n1, $n2, $attrs, $col) = @_;
  die if !$n1 || !$n2;
  my $str = '';
  $str .= $col . &str4node($n1) . " -> " . &str4node($n2);
  $str .= &str4attrs($attrs);
  $str .= ";\n";
  return $str;
}
sub str4graph {
  my ($scope, $col) = @_;
  my $str = '';
  my $label = $$scope{'label'};

  if ($label) {
    $str .= $col . "$$scope{'type'} \"$label\" {\n";
  } else {
    $str .= $col . "$$scope{'type'} {\n";
  }
  $col = &colin($col);

  foreach my $node (sort keys %$keyword) {
    if ($$scope{'nodes'}{$node}) {
      $str .= &strln4node($node, $$scope{'nodes'}{$node}, $col);
    }
    delete $$scope{'nodes'}{$node};
  }
  $str .= "\n";
  foreach my $subgraph (@{$$scope{'subgraphs'}}) {
    if ($subgraph) {
      $str .= &str4graph($subgraph, $col);
    }
  }
  foreach my $n_name (sort keys %{$$scope{'nodes'}}) {
    my $n_attrs = $$scope{'nodes'}{$n_name};
    $str .= &strln4node($n_name, $n_attrs, $col);
  }
  $str .= "\n" if 0 < keys %{$$scope{'edges'}};
  foreach my $n1_name (sort keys %{$$scope{'edges'}}) {
    my $info = $$scope{'edges'}{$n1_name};
    my ($n2_name, $edge_attrs);
    foreach my $n2_name (sort keys %$info) {
      my $edge_attrs = $$info{$n2_name};
      $str .= &strln4edge($n1_name, $n2_name, $edge_attrs, $col);
    }
  }
  $col = &colout($col);
  $str .= $col . "}\n";
  return $str;
}
sub empty_graph {
  my ($type) = @_;
  my $graph = eval "{ 'type' => '$type', 'label' => undef, 'nodes' => {}, 'edges' => {}, 'subgraphs' => [] }";
  return $graph;
}

sub start {
  my ($opts, $repository) = @_;

  $repository = &path($repository);
  my ($rdir, $name, $ext) = &rdir_name_ext($repository);
  my $result = `../bin/dakota-project name --repository $repository --var SO_EXT=$SO_EXT`;
  chomp $result;

  my $so_files = [split("\n", `../bin/dakota-project libs --repository $repository --var SO_EXT=$SO_EXT`)];
  my $dk_files = [split("\n", `../bin/dakota-project srcs --repository $repository`)];

  my $graph = &empty_graph('digraph');
  $$graph{'label'} = &path($result);
  &add_node($graph, 'graph', {
    'rankdir' => 'RL',
    'label' => '\G',
    'fontcolor' => 'red',
    #'page' => '8.5,11',
    #'size' => '7.5,10',
    #'center' => 'true',
    });
  &add_node($graph, 'edge', { 'colorscheme' => $colorscheme });
  &add_node($graph, 'node', { 'shape' => 'rect', 'width' => 1.5,
                              'style' => 'rounded',
                              'height' => 0.25 });
  ($rdir, $name, $ext) = &rdir_name_ext($result);
  my $rt_rep_file = &path("$obj/rt/$rdir/$name.rep");
  my $rt_hh_file =  &path("$obj/rt/$rdir/$name.hh");
  my $rt_cc_file =  &path("$obj/rt/$rdir/$name.cc");
  my $rt_o_file =   &path("$obj/rt/$rdir/$name.o");

  my $cc_files = {};
  $$cc_files{$rt_cc_file} = undef;

  if ($show_headers) {
    &add_node($graph, $rt_hh_file, { 'colorscheme' => $colorscheme, 'color' => 4 });
  }
  &add_node($graph, $rt_cc_file, { 'colorscheme' => $colorscheme, 'color' => 4 });
  &add_node($graph, $result, { 'style' => 'none' });

  foreach my $so_file (@$so_files) {
    my ($rdir, $name, $ext) = &rdir_name_ext($so_file);
    my $ctlg_file = &path("$obj/$rdir/$name.ctlg");
    my $rep_file =  &path("$obj/$rdir/$name.rep");

    &add_node($graph, $so_file, { 'style' => 'none' });

    &add_edge($graph, $ctlg_file,   $so_file,   { 'color' => 1 });
    &add_edge($graph, $rep_file,    $ctlg_file, { 'color' => 2 });
    &add_edge($graph, $rt_rep_file, $rep_file,  { 'color' => 3 });
  }
  my $nrt_rep_files = {};
  my $o_files = {};

  foreach my $dk_file (@$dk_files) {
    my ($rdir, $name, $ext) = &rdir_name_ext($dk_file);
    my $dk_cc_file =   &path("$obj/$rdir/$name.cc");
    my $nrt_rep_file = &path("$obj/nrt/$rdir/$name.rep");
    my $nrt_hh_file =  &path("$obj/nrt/$rdir/$name.hh");
    my $nrt_cc_file =  &path("$obj/nrt/$rdir/$name.cc");
    my $nrt_o_file =   &path("$obj/nrt/$rdir/$name.o");

    $$nrt_rep_files{$nrt_rep_file} = undef;
    $$o_files{$nrt_o_file} = undef;
    $$cc_files{$nrt_cc_file} = undef;
    $$cc_files{$dk_cc_file} = undef;

    &add_node($graph, $dk_cc_file, { 'style' => "rounded,bold" });;

    &add_edge($graph, $nrt_rep_file, $dk_file,     { 'color' => 1 });
    &add_edge($graph, $dk_cc_file,   $dk_file,     { 'color' => 4 });

    if (1) {
      &add_edge($graph, $dk_cc_file,   $rt_rep_file, { 'color' => 0, 'style' => 'dashed' });
      &add_edge($graph, $nrt_cc_file,  $rt_rep_file, { 'color' => 0, 'style' => 'dashed' });
    }
    &add_edge($graph, $nrt_o_file,   $nrt_cc_file,  { 'color' => 5 });

    if ($show_headers) {
      &add_edge($graph, $nrt_hh_file, $rt_rep_file,  { 'color' => 0, 'style' => 'dashed' });
      &add_edge($graph, $nrt_hh_file, $nrt_rep_file, { 'color' => 4 });
      &add_edge($graph, $nrt_o_file,  $nrt_hh_file,  { 'color' => 5 });
    }

    &add_edge($graph, $nrt_cc_file,  $nrt_rep_file, { 'color' => 4 });
    &add_edge($graph, $nrt_o_file,   $nrt_cc_file,  { 'color' => 5 });
  }
  foreach my $nrt_rep_file (sort keys %$nrt_rep_files) {
    &add_edge($graph, $rt_rep_file, $nrt_rep_file, { 'color' => 3 });
  }
  if ($show_headers) {
    &add_edge($graph, $rt_hh_file, $rt_rep_file, { 'color' => 4 });
    &add_edge($graph, $rt_o_file,  $rt_hh_file,  { 'color' => 5 });
  }

  &add_edge($graph, $rt_cc_file, $rt_rep_file, { 'color' => 4 });
  &add_edge($graph, $rt_o_file,  $rt_cc_file,  { 'color' => 5 });
  &add_edge($graph, $result,     $rt_o_file,   { 'color' => 0 }); # black indicates no concurrency (linking)

  foreach my $o_file (sort keys %$o_files) {
    &add_edge($graph, $result, $o_file, { 'color' => 0 }); # black indicates no concurrency (linking)
  }

  ###
  my $subgraph = &empty_graph('subgraph');
  &add_node($subgraph, 'graph', { 'rank' => 'same' });
  foreach my $input_file (@$so_files, @$dk_files) {
    &add_node($subgraph, $input_file, undef);
  }
  &add_subgraph($graph, $subgraph);
  ###
  ###
  $subgraph = &empty_graph('subgraph');
  &add_node($subgraph, 'graph', { 'rank' => 'same' });
  foreach my $cc_file (keys %$cc_files) {
    &add_node($subgraph, $cc_file, undef);
  }
  &add_subgraph($graph, $subgraph);
  ###

  print &str4graph($graph, '');

  ($rdir, $name, $ext) = &rdir_name_ext($repository);
  my $make_targets = "$rdir/$name.mk";
  open FILE, ">$make_targets" or die __FILE__, ":", __LINE__, ": ERROR: $make_targets: $!\n";

  foreach my $n1 (sort keys %{$$graph{'edges'}}) {
    print FILE "$n1:\\\n";
    my ($n2, $attr);
    foreach my $n2 (sort keys %{$$graph{'edges'}{$n1}}) {
      #my $attr = $$edges{$n1}{$n2};
      print FILE " $n2\\\n";
    }
    print FILE "#\n"
  }
  close FILE;

  ($rdir, $name, $ext) = &rdir_name_ext($repository);
  my $data = "$rdir/$name.data";
  open DATA, ">$data" or die __FILE__, ":", __LINE__, ": ERROR: $data: $!\n";
  print DATA &Dumper($graph);
  close DATA;
}

unless (caller) {
  use Getopt::Long;
  $Getopt::Long::ignorecase = 0;
  my $opts = {};
  &GetOptions($opts,
              'output=s');
  die "Too many args." if @ARGV > 1;
  my $repository;

  if (@ARGV == 1) {
    $repository = $ARGV[0];
  } else {
    $repository = 'dummy-project.rep';
  }
  &start($opts, $repository);
}

1;
