#!/usr/bin/perl -w

use strict;

my $use_multiple_returns = 0; # 0 or 1
my $should_reverse_order = 0; # 0 or 1
my $fail = 0; # 0 or ...
my $base = 1; # 1 or ...

my $hdr_ext = 'h';

my $NUL = '\0';

unless (caller) {
    my $in_strs = [];
    while (<STDIN>) {
	chomp $_;
	if (0 != length($_)) {
	    push @$in_strs, $_;
	}
    }
    my $args = eval($ARGV[0]) or die;
    $$args{'name'} = [split('::', $$args{'name'})];
    $$args{'fs-name'} = join('--', @{$$args{'name'}});
    my ($hdr, $src) = &gen_mph($in_strs, $args);
    if (0) {
	$src =~ s|\s*{\s*|\n{\n|g;
	#$src =~ s|\n{\n| {\n|g;
	$src =~ s|\s*}\s*|\n}\n|g;
	$src =~ s|\n\s*\n|\n|g;
	$src =~ s|^\s+||gm;
    }
    my $src_ext;
    if (1 < @{$$args{'name'}}) {
	$src_ext = 'cc';
    }
    elsif (1 == @{$$args{'name'}}) {
	$src_ext = 'c';
    }
    else { die; }
    my $fh;

    open($fh, ">", "$$args{'fs-name'}.$hdr_ext");
    print $fh $hdr;
    close $fh;

    open($fh, ">", "$$args{'fs-name'}.$src_ext");
    print $fh $src;
    close $fh;
}
sub gen_mph
{
    my ($strs, $args) = @_;

    if (defined  $$args{'use-multiple-returns'}) {
	$use_multiple_returns = $$args{'use-multiple-returns'};
    }
    if (defined  $$args{'should-reverse'}) {
	$should_reverse_order = $$args{'should-reverse-order'};
    }
    if (defined  $$args{'fail'}) {
	$fail = $$args{'fail'};
    }
    if (defined  $$args{'base'}) {
	$base = $$args{'base'};
    }

    my $name = $$args{'name'};
    my $bname = @$name[-1];
    my $BNAME = uc join('__', @$name);

    my $gen_mph_func_args = {
	'strs' => $strs,
	'names' => {
	    'fs-name' => $$args{'fs-name'},
	    'bname' => $bname,

	    'hash' =>    "${bname}_hash",
	    'strs' => "${bname}_strs",

	    'FAIL' =>        "${BNAME}_FAIL",
	    'BASE' =>        "${BNAME}_BASE",
	    'STRS_LEN' => "${BNAME}_STRS_LEN"
	}
    };
    my $macro_guard = "__${BNAME}_H__";

    my $hdr = '';
    $hdr .= "#ifndef $macro_guard\n";
    $hdr .= "#define $macro_guard\n\n";
    $hdr .= "#include \"mph.h\"\n\n";
    $hdr .= &gen_in_ns(0, $name, \&gen_hdr, $gen_mph_func_args);
    $hdr .= "\n";
    $hdr .= "#endif\n";

    my $src = '';
    $src .= "#include <stdlib.h>\n\n";
    $src .= "#include \"$$args{'fs-name'}.$hdr_ext\"\n\n";
    $src .= "#ifndef NUL\n";
    $src .= "#define NUL '$NUL'\n";
    $src .= "#endif\n\n";
    $src .= &gen_in_ns(0, $name, \&gen_mph_func, $gen_mph_func_args);
    if (0) {
	$src =~ s|}\s*break\s*;\s*}|} break; }|gs;
    }

    return ($hdr, $src);
}
sub gen_in_ns
{
    my ($col, $name, $callback, $callback_args) = @_;
    my $result = '';
    my $len = @$name; # len must be >= 1
    if (1 == $len) {
	$result .= $callback->($col, $callback_args);
    }
    else {
	&append_col(\$result, $col, "namespace $$name[0] {\n");
	$result .= &gen_in_ns($col + 1, [@$name[1 .. $len - 1]], $callback, $callback_args);
	&append_col(\$result, $col, "}\n");
    }
    return $result;
}
sub gen_hdr
{
    my ($col, $args) = @_;
    my $result = '';
    &append_col(\$result, $col, "extern const mph_t $$args{'names'}{'bname'};\n");
    return $result;
}

sub gen_mph_func
{
    my ($col, $args) = @_;
    my $result = '';
    my $strs = $$args{'strs'};
    my $names = $$args{'names'};
    my $tree = &gen_tree($strs);
    
    my $debug = 1;
    if ($debug) {
	use Data::Dumper;
	$Data::Dumper::Terse     = 1;
	$Data::Dumper::Deepcopy  = 1;
	$Data::Dumper::Purity    = 1;
	$Data::Dumper::Quotekeys = 1;
	$Data::Dumper::Sortkeys =  1;
	$Data::Dumper::Indent    = 1; # default = 2

	open OUT, ">$$names{'fs-name'}.pl" or die "$!\n";
	print OUT &Dumper($tree);
	close OUT or die "$!\n";
    }
    my $int = "int";
    my $type = "unsigned $int";
    my $v = 0;
    if ($should_reverse_order) {
	$v = @$strs - 1;
    }
    my $strs_len = scalar @$strs;
    &append_col(\$result, $col, "#define $$names{'FAIL'}     $fail\n");
    &append_col(\$result, $col, "#define $$names{'BASE'}     $base\n");
    &append_col(\$result, $col, "#define $$names{'STRS_LEN'} $strs_len\n");
    $result .= "\n";

    &append_col(\$result, $col, "#if $$names{'FAIL'} >= $$names{'BASE'} && $$names{'FAIL'} <= $$names{'BASE'} + $$names{'STRS_LEN'} - 1\n");
    &append_col(\$result, $col + 1, "#error \"codegen error: $$names{'FAIL'} falls in range of success values\"\n");
    &append_col(\$result, $col, "#endif\n\n");

    &append_col(\$result, $col, "static const char* const $$names{'strs'}\[$$names{'STRS_LEN'}] = {\n");
    $col++;
    foreach my $str (sort @$strs) {
	&append_col(\$result, $col, "\"$str\",\n");
    }
    $result =~ s|,\n$|\n|;
    $col--;
    &append_col(\$result, $col, "};\n");
    &append_col(\$result, $col, "static PURE unsigned $int $$names{'hash'}(const char* str);\n");

    &append_col(\$result, $col, "const mph_t $$names{'bname'} = {\n");
    $col++;
    &append_col(\$result, $col, "$$names{'hash'},\n");
    &append_col(\$result, $col, "$$names{'FAIL'},\n");
    &append_col(\$result, $col, "$$names{'BASE'},\n");
    &append_col(\$result, $col, "$$names{'STRS_LEN'},\n");
    &append_col(\$result, $col, "$$names{'strs'}\n");
    $col--;
    &append_col(\$result, $col, "};\n");

    &append_col(\$result, $col, "static PURE unsigned $int $$names{'hash'}(const char* str) {\n");
    $col++;

    &append_col(\$result, $col, "if (nullptr != str) {\n");
    $col++;
    my $i = 0;
    &append_col(\$result, $col, "switch (str[$i]) {\n");
    $col++;
    my $str;
    &gen_mph_func_recursive($tree, $i + 1, \$v, $str = [], \$result, $col, $names);
    if ($use_multiple_returns) {
	&append_col(\$result, $col, "default: return $$names{'FAIL'};\n");
    }
    $col--;
    &append_col(\$result, $col, "}\n"); # switch
    $col--;
    &append_col(\$result, $col, "}\n"); # if
    &append_col(\$result, $col, "return $$names{'FAIL'};\n");
    $col--;
    &append_col(\$result, $col, "}\n"); # function

    return $result;
}
sub gen_mph_func_recursive
{
    my ($tree, $i, $v, $str, $result, $col, $names) = @_;
    my $chars = &order([ keys %$tree ]);
    foreach my $char (@$chars) {
	if ($NUL eq $char) {
	    $" = '';
	    &append_col($result, $col, "case NUL: return $$names{'BASE'} + $$v; /*\"@$str\"*/\n");
	    if ($should_reverse_order) {
		$$v--;
	    } else {
		$$v++;
	    }
        }
        else {
	    &append_col($result, $col, "case '$char': {\n");
	    $col++;
	    &append_col($result, $col, "switch (str[$i]) {\n");
	    $col++;
	    push @$str, $char;
            &gen_mph_func_recursive($$tree{$char}, $i + 1, $v, $str, $result, $col, $names);
	    pop @$str;
	    my $j = $i - 1;
	    if ($use_multiple_returns) {
		&append_col($result, $col, "default: return $$names{'FAIL'};\n");
	    }
	    $col--;
	    &append_col($result, $col, "}\n"); # switch
	    #&append_col($result, $col, "break; /*switch (str[$j]) case '$char'*/\n");
	    &append_col($result, $col, "break;\n");
	    $col--;
	    &append_col($result, $col, "}\n"); # case
        }
    }
}
sub order
{
    my ($strs) = @_;
    my $result = [ sort @$strs ];
    if ($should_reverse_order) {
	$result = [ reverse @$result ];
    }
    return $result;
}
sub gen_tree
{
    my ($strs) = @_;
    my $result = {};
    $strs = &order($strs);
    foreach my $str (@$strs) {
        my $chars = [split //, $str];

	my $current_context = $result;
        foreach my $char (@$chars) {
	    if (!$$current_context{$char}) {
		$$current_context{$char} = {};
	    }
	    $current_context = $$current_context{$char};
	}
	$$current_context{$NUL} = $str;
    }
    return $result;
}
sub append_col
{
    my ($result, $col_num, $string) = @_;
    $col_num *= 2;
    my $pad = '';
    $pad .= ' ' x $col_num;
    $$result .= $pad;
    $$result .= $string;
    return $$result;
}
