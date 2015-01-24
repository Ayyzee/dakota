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
  if (!exists $$tbl{$n}) {
    $$tbl{$n} = $attrs;
  } else {
    die;
  }
}
sub add_edge {
  my ($tbl, $e1, $e2, $attrs) = @_;

  if (!exists $$tbl{$e1}) {
    $$tbl{$e1} = undef;
  }
  if (!exists $$tbl{$e1}{$e2}) {
    $$tbl{$e1}{$e2} = $attrs;
  } else {
    die;
  }
}
sub add_subgraph {
  my ($tbl, $name) = @_;
  if (!$$tbl{$name}) {
    $$tbl{$name} = {};
  }
}
sub str4attrs {
  my ($attrs) = @_;
  my $str = '';
  if ($attrs) {
    my $d = '';
    $str .= " \[";
    my ($key, $val);
    while (($key, $val) = each (%$attrs)) {
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
  my $str = '';
  $str .= $col . &str4node($n1) . " -> " . &str4node($n2);
  $str .= &str4attrs($attrs);
  $str .= ";\n";
  return $str;
}
sub str4graph {
  my ($scope, $type, $name, $col) = @_;
  my $str = '';

  $str .= $col . "$type \"$name\" {\n";
  $col = &colin($col);

  foreach my $node (keys %$keyword) {
    if ($$scope{$name}{'nodes'}{$node}) {
      $str .= &strln4node($node, $$scope{$name}{'nodes'}{$node}, $col);
    }
    #delete $$scope{'nodes'}{$node};
  }
  my ($subname, $subscope);
  while (($subname, $subscope) = each (%{$$scope{$name}{'subgraphs'}})) {
    if ($subscope) {
      $str .= &str4graph($$scope{$name}{'subgraphs'}, 'subgraph', $subname, $col);
    }
  }
  my ($n_name, $n_attrs);
  while (($n_name, $n_attrs) = each (%{$$scope{$name}{'nodes'}})) {
    if (!$$keyword{$n_name}) {
      $str .= &strln4node($n_name, $n_attrs, $col);
    }
  }
  my ($n1_name, $info);
  while (($n1_name, $info) = each (%{$$scope{$name}{'edges'}})) {
    my ($n2_name, $edge_attrs);
    while (($n2_name, $edge_attrs) = each (%$info)) {
      $str .= &strln4edge($n1_name, $n2_name, $edge_attrs, $col);
    }
  }
  $col = &colout($col);
  $str .= $col . "}\n";
  return $str;
}

sub start {
  my ($opts, $repository) = @_;

  $repository = &path($repository);
  my ($rdir, $name, $ext) = &rdir_name_ext($repository);
  my $graph_name = &path("$rdir/$name");
  my $subgraph_name = 'input-files';

  my $result = `../bin/dakota-project name --repository $repository --var SO_EXT=$SO_EXT`;
  chomp $result;

  my $so_files = [split("\n", `../bin/dakota-project libs --repository $repository --var SO_EXT=$SO_EXT`)];
  my $dk_files = [split("\n", `../bin/dakota-project srcs --repository $repository`)];

  my $graph = { $graph_name => { 'nodes' => {}, 'edges' => {}, 'subgraphs' => { $subgraph_name => { 'nodes' => {}, 'edges' => {} }}}};

  &add_node($$graph{$graph_name}{'nodes'}, 'graph', { 'label' => '\G',
                               'fontcolor' => 'red',
                               #'page' => '8.5,11',
                               #'size' => '7.5,10',
                               #'center' => 'true',
                               'rankdir' => 'RL' });
  &add_node($$graph{$graph_name}{'nodes'}, 'edge', { 'colorscheme' => $colorscheme });
  &add_node($$graph{$graph_name}{'nodes'}, 'node', { 'shape' => 'rect',
                              'style' => 'rounded',
                              'height' => 0.25 });

  my $input_files = [ @$so_files, @$dk_files ];
  &add_subgraph($$graph{$graph_name}{'subgraphs'}, $subgraph_name);
  &add_node($$graph{$graph_name}{'subgraphs'}{$subgraph_name}{'nodes'}, 'graph', { 'rank' => 'same' });
  foreach my $input_file (@$so_files, @$dk_files) {
    &add_node($$graph{$graph_name}{'subgraphs'}{$subgraph_name}{'nodes'}, $input_file, undef);
  }

  ($rdir, $name, $ext) = &rdir_name_ext($result);
  my $rt_rep_file = &path("$obj/rt/$rdir/$name.rep");
  my $rt_hh_file =  &path("$obj/rt/$rdir/$name.hh");
  my $rt_cc_file =  &path("$obj/rt/$rdir/$name.cc");
  my $rt_o_file =   &path("$obj/rt/$rdir/$name.o");

  if ($show_headers) {
    $$graph{$graph_name}{'nodes'}{$rt_hh_file}{'colorscheme'} = $colorscheme;
    $$graph{$graph_name}{'nodes'}{$rt_hh_file}{'color'} = 4;
  }
  $$graph{$graph_name}{'nodes'}{$rt_cc_file}{'colorscheme'} = $colorscheme;
  $$graph{$graph_name}{'nodes'}{$rt_cc_file}{'color'} = 4;

  &add_node($$graph{$graph_name}{'nodes'}, $result, { 'style' => 'none' });
  foreach my $so_file (@$so_files) {
    my ($rdir, $name, $ext) = &rdir_name_ext($so_file);
    my $ctlg_file = &path("$obj/$rdir/$name.ctlg");
    my $rep_file =  &path("$obj/$rdir/$name.rep");
    &add_node($$graph{$graph_name}{'nodes'}, $so_file, { 'style' => 'none' });

    &add_edge($$graph{$graph_name}{'edges'}, $ctlg_file,   $so_file,   { 'color' => 1 });
    &add_edge($$graph{$graph_name}{'edges'}, $rep_file,    $ctlg_file, { 'color' => 2 });
    &add_edge($$graph{$graph_name}{'edges'}, $rt_rep_file, $rep_file,  { 'color' => 3 });
  }
  my $nrt_rep_files = {};
  my $o_files = {};

  foreach my $dk_file (@$dk_files) {
    my ($rdir, $name, $ext) = &rdir_name_ext($dk_file);
    my $nrt_rep_file = &path("$obj/$rdir/$name.rep");
    my $dk_cc_file =   &path("$obj/$rdir/$name.cc");
    my $nrt_hh_file =  &path("$obj/nrt/$rdir/$name.hh");
    my $nrt_cc_file =  &path("$obj/nrt/$rdir/$name.cc");
    my $nrt_o_file =   &path("$obj/nrt/$rdir/$name.o");

    &add_node($$graph{$graph_name}{'nodes'}, $dk_cc_file, { 'style' => "rounded,bold" });;

    $$nrt_rep_files{$nrt_rep_file} = undef;
    $$o_files{$nrt_o_file} = undef;

    &add_edge($$graph{$graph_name}{'edges'}, $nrt_rep_file, $dk_file,     { 'color' => 1 });
    &add_edge($$graph{$graph_name}{'edges'}, $dk_cc_file,   $dk_file,     { 'color' => 4 });
    if (1) {
      &add_edge($$graph{$graph_name}{'edges'}, $dk_cc_file,   $rt_rep_file, { 'color' => 0 }); # gray, dashed
      &add_edge($$graph{$graph_name}{'edges'}, $nrt_cc_file,  $rt_rep_file, { 'color' => 0 }); # gray, dashed
    }
    &add_edge($$graph{$graph_name}{'edges'}, $nrt_o_file,   $dk_cc_file,  { 'color' => 5 });

    if ($show_headers) {
      &add_edge($$graph{$graph_name}{'edges'}, $nrt_hh_file, $rt_rep_file,  { 'color' => 0 }); # gray, dashed
      &add_edge($$graph{$graph_name}{'edges'}, $nrt_hh_file, $nrt_rep_file, { 'color' => 4 });
      &add_edge($$graph{$graph_name}{'edges'}, $nrt_o_file,  $nrt_hh_file,  { 'color' => 5 });
    }

    &add_edge($$graph{$graph_name}{'edges'}, $nrt_cc_file,  $nrt_rep_file, { 'color' => 4 });
    &add_edge($$graph{$graph_name}{'edges'}, $nrt_o_file,   $nrt_cc_file,  { 'color' => 5 });
  }
  foreach my $nrt_rep_file (sort keys %$nrt_rep_files) {
    &add_edge($$graph{$graph_name}{'edges'}, $rt_rep_file, $nrt_rep_file, { 'color' => 3 });
  }
  if ($show_headers) {
    &add_edge($$graph{$graph_name}{'edges'}, $rt_hh_file, $rt_rep_file, { 'color' => 4 });
    &add_edge($$graph{$graph_name}{'edges'}, $rt_o_file,  $rt_hh_file, { 'color' => 5 });
  }

  &add_edge($$graph{$graph_name}{'edges'}, $rt_cc_file, $rt_rep_file, { 'color' => 4 });
  &add_edge($$graph{$graph_name}{'edges'}, $rt_o_file,  $rt_cc_file, { 'color' => 5 });

  foreach my $o_file (sort keys %$o_files) {
    &add_edge($$graph{$graph_name}{'edges'}, $result, $o_file, { 'color' => 0 }); # black indicates no concurrency (linking)
  }
  &add_edge($$graph{$graph_name}{'edges'}, $result, $rt_o_file, { 'color' => 0 }); # black indicates no concurrency (linking)

  print &str4graph($graph, 'digraph', $graph_name, '');

  ($rdir, $name, $ext) = &rdir_name_ext($repository);
  my $make_targets = "$rdir/$name.mk";
  open FILE, ">$make_targets" or die __FILE__, ":", __LINE__, ": ERROR: $make_targets: $!\n";

  foreach my $e1 (sort keys %{$$graph{$graph_name}{'edges'}}) {
    print FILE "$e1:\\\n";
    my ($e2, $attr);
    foreach my $e2 (sort keys %{$$graph{$graph_name}{'edges'}{$e1}}) {
      #my $attr = $$edges{$e1}{$e2};
      print FILE " $e2\\\n";
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
