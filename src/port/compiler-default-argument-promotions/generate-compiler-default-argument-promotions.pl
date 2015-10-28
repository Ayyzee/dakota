#!/usr/bin/perl -w
# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

use strict;
use warnings;

# http://en.cppreference.com/w/cpp/types/numeric_limits/is_signed

my $extra = 2; # NEVER set this to 1

my $type_tbl = {
  'int-t' => {
    'schar8-t'             => 1,
    'schar8::slots-t'      => 1,

    'int8-t'               => 1,
    'int8::slots-t'        => 1,
    'int16-t'              => 1,
    'int16::slots-t'       => 1,
    'int32-t'              => 1,
    'int32::slots-t'       => 1,
    'int64-t'              => 1,
    'int64::slots-t'       => 1,

    'int-least8-t'         => 1,
    'int-least8::slots-t'  => 1,
    'int-least16-t'        => 1,
    'int-least16::slots-t' => 1,
    'int-least32-t'        => 1,
    'int-least32::slots-t' => 1,
    'int-least64-t'        => 1,
    'int-least64::slots-t' => 1,

    'int-fast8-t'          => 1,
    'int-fast8::slots-t'   => 1,
    'int-fast16-t'         => 1,
    'int-fast16::slots-t'  => 1,
    'int-fast32-t'         => 1,
    'int-fast32::slots-t'  => 1,
    'int-fast64-t'         => 1,
    'int-fast64::slots-t'  => 1,
  },
  'uint-t' => {
    'boole-t'               => 1,
    'boole::slots-t'        => 1,

    'uchar8-t'              => 1,
    'uchar8::slots-t'       => 1,

    'char16-t'              => 1, # yes, unsigned
    'char16::slots-t'       => 1, # yes, unsigned

    'char32-t'              => 1, # yes, unsigned
    'char32::slots-t'       => 1, # yes, unsigned

    'uint8-t'               => 1,
    'uint8::slots-t'        => 1,
    'uint16-t'              => 1,
    'uint16::slots-t'       => 1,
    'uint32-t'              => 1,
    'uint32::slots-t'       => 1,
    'uint64-t'              => 1,
    'uint64::slots-t'       => 1,

    'uint-least8-t'         => 1,
    'uint-least8::slots-t'  => 1,
    'uint-least16-t'        => 1,
    'uint-least16::slots-t' => 1,
    'uint-least32-t'        => 1,
    'uint-least32::slots-t' => 1,
    'uint-least64-t'        => 1,
    'uint-least64::slots-t' => 1,

    'uint-fast8-t'          => 1,
    'uint-fast8::slots-t'   => 1,
    'uint-fast16-t'         => 1,
    'uint-fast16::slots-t'  => 1,
    'uint-fast32-t'         => 1,
    'uint-fast32::slots-t'  => 1,
    'uint-fast64-t'         => 1,
    'uint-fast64::slots-t'  => 1,
  },
  'double-t' => {
    'float32-t'         => 1,
    'float32::slots-t'  => 1,

    'float64-t'         => 1,
    'float64::slots-t'  => 1,

    'float128-t'        => 1,
    'float128::slots-t' => 1,
  },
};
my $implementation_defined_signedness = {
  'char8-t'          => 1,
  'char8::slots-t'   => 1,

  'wchar-t'          => 1
};
`make type-index`;
my $index = `./type-index`;
my $int_types = [ 'uint-t', 'int-t' ];

foreach my $type (sort keys %$implementation_defined_signedness) {
  if ($type && $extra != $$implementation_defined_signedness{$type} ) {
    $$type_tbl{$$int_types[$index]}{$type} = $$implementation_defined_signedness{$type};
  }
}
my $result_tbl = {};
my $unpromoted = {};
undef $/;
while (my ($promoted_type, $types) = each(%$type_tbl)) {
  for my $small_type (sort keys %$types) {
    if ($extra == $$types{$small_type}) {
      next;
    }
    my $in_name = 'exe-main-template.dk';
    open(my $fh, '<', $in_name) or die "Could not open file '$in_name' $!";
    my $filestr = <$fh>;
    close($fh);
    $filestr =~ s/__TYPE__/$small_type/;
    `make clean`;
    my $out_name = 'exe-main.dk';
    open(my $out, '>', $out_name)  or die "Could not open file '$out_name' $!";
    print $out $filestr;
    close($out);
    #print "small-type: " . $small_type . "\n";
    my $cmd = "make exe";
    my $output = `$cmd`; # 2>&1
    my $exit_val = $?;
    print $output;
    #print "exit-val: " . $exit_val . "\n";
    if ($exit_val) {
      $$result_tbl{$small_type} = $promoted_type;
    } else {
      $$unpromoted{$small_type} = 1;
    }
  }
}
use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Useqq     = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Indent    = 1; # default = 2

my $str;
$str = &Dumper($result_tbl);
$str =~ s/\{[\s\n]*"/\{ "/gs;
$str =~ s/1[\s\n]*\}/1 \}/gs;
my $fn = "compiler-default-argument-promotions.json";
open(my $fh, '>', $fn) or die "Could not open file '$fn' $!";
print $fh $str;
close($fh);
print "# result written to $fn\n";
$str = &Dumper($unpromoted);
print "# NOT promoted:\n";
print $str;
