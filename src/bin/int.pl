#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my $db = {};

my $bases = [ 'int', 'uint' ];
my $modifiers = [ '_least', '_fast' ];
my $widths = [ 8, 16, 32, 64];

# ptrdiff_t, size_t, wchar_t

my $other_types = { 'intptr_t' => { 'max' => 'intptr_max', 'min' => 'intptr_min' },
                    'uintptr_t' => { 'max' => 'uintptr_max', },
};

my ($key, $val);
while (($key, $val) = each (%$other_types)) {
    $$db{$key}{'max'} = uc $$val{'max'};
    if (defined $$val{'min'}) {
        $$db{$key}{'min'} = uc $$val{'min'};
    }
}
sub make1
{
    my ($db, $base, $modifier, $width) = @_;
    my $type = "$base$modifier${width}_t";

    my $max_macro = uc "$base$modifier${width}_max";
    $$db{$type}{'max'} = $max_macro;

    if ('int' eq $base) {
        my $min_macro = uc "$base$modifier${width}_min";
        $$db{$type}{'min'} = $min_macro;
    }
}
sub make2
{
    my ($db, $base, $width) = @_;
    my $type = "$base${width}_t";
    my $int_const_macro = uc "$base${width}_c";
    $int_const_macro .= "(v)";
    $$db{$type}{'constant'} = $int_const_macro;
    &make1($db, $base, '', $width);
}

foreach my $base (@$bases) {
    foreach my $modifier (@$modifiers) {
        foreach my $width (@$widths) {
            &make1($db, $base, $modifier, $width);
        }
    }
}

foreach my $base (@$bases) {
    foreach my $width (@$widths, 'max') {
        &make2($db, $base, $width);
    }
}

#print &Dumper($db);

# http://pubs.opengroup.org/onlinepubs/009695399/basedefs/inttypes.h.html

my ($type, $info);
my $module_exports = "module dakota export\n";
foreach my $type (sort keys %$db) {
    my $info = $$db{$type};
    $type =~ s/_/-/g;
    my $klass_name = $type;
    $klass_name =~ s/-t$//;
    $module_exports .=
        "  $klass_name,\n" .
        "  $klass_name:slots-t,\n";
    my $kls_defn =
        "klass $klass_name\n" .
        "{\n" .
        "  slots $type;\n" .
        "\n";
    if ($$info{'min'}) {
        $kls_defn .=
            "  const slots-t min = $$info{'min'};\n";
        $module_exports .= "  $klass_name:min,\n";
    }
    $kls_defn .=
        "  const slots-t max = $$info{'max'};\n";
    $module_exports .= "  $klass_name:max,\n";

    if ($$info{'constant'}) {
        $kls_defn .=
            "\n" .
            "  // $$info{'constant'}\n";
    }
    $kls_defn .=    
        "}\n";
    print $kls_defn;
}
print $module_exports;

# printf signed integers
# PRId[N]
# PRIi[N]

# printf unsigned integers
# PRIo[N]
# PRIu[N]
# PRIx[N]
# PRIX[N]
