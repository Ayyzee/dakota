#!/usr/bin/perl -w

use strict;
use Data::Dumper;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;

$main::block = qr{
                    \{
                    (?:
                       (?> [^{}]+ )         # Non-braces without backtracking
                       |
                       (??{ $main::block }) # Group with matching braces
                    )*
                    \}
                 }x;

$main::list = qr{
                    \(
                    (?:
                       (?> [^()]+ )         # Non-parens without backtracking
                       |
                       (??{ $main::list }) # Group with matching parens
                    )*
                    \)
                 }x;

# same code in Dakota.pm
my $k  = qr/[a-z0-9-]+/; # dakota identifer
my $ak = qr/:$k/;     # absolute scoped dakota identifier
my $rk = qr/$k$ak*/;  # relative scoped dakota identifier
undef $/;

my $root = { 'klass' => {}, 'trait' => {} };
my $klasses = {};
my $traits = {};
my $method_to_generics = {};
my $generic_to_methods = {};
my $generic_to_klasses = {};
my $va_methods =  {};
my $va_generics = {};

my $klass_to_superklass = {};
my $klass_to_methods =    {};
my $klass_to_traits =     {};

sub normalize_signature
{
    my ($signature) = @_;
    return $signature;
}

sub method::compare
{
    my ($a_type, $a_name, $a_rest) = split /\s/, $a;
    my ($b_type, $b_name, $b_rest) = split /\s/, $b;

    return $a_name cmp $b_name;
}

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts= {};
&GetOptions($opts,
            'simple',
            'output=s',
            'directory=s',
            );

if($$opts{output})
{
    open(STDOUT, ">$$opts{output}") or die("$$opts{output}: $!\n");
}

while(<>)
{
    s/\/\/.*?$//gm;
    s/\/\*.*?\*\///gs;

    while(/(klass|trait)\s+($rk)\s*($main::block)/gc)
    {
	my $klass_type  = $1;
	my $klass_name  = $2;
	my $klass_block = $3;
	$$method_to_generics{$klass_type}{$klass_name} = {};

	$$root{$klass_type}{$klass_name} = undef;

	if ('klass' eq $klass_type)
	{
	    $$klasses{$klass_name} = undef;

	    if ($klass_block =~ m/(superklass)\s+($rk)\s*;/gc)
	    {
		my $superklass_name = $2;
		$$klass_to_superklass{$klass_name} = $superklass_name;
	    }
	    else
	    {
		if ('object' ne $klass_name)
		{
		    $$klass_to_superklass{$klass_name} = 'object';
		}
	    }
	}
	elsif ('trait' eq $klass_type)
	{
	    $$traits{$klass_name} = undef;
	}
	else
	{ die; }

	while($klass_block =~ m/\s*(trait)\s+($rk)\s*;/gc)
	{
	    my $decl_type = $1;
	    my $decl_name = $2;

	    if (!exists $$root{$klass_type}{$klass_name}{$decl_type})
	    { $$root{$klass_type}{$klass_name}{$decl_type} = []; }
	    push @{$$root{$klass_type}{$klass_name}{$decl_type}}, $decl_name;

	    $$klass_to_traits{$klass_name}{$decl_name} = $decl_type;
	}
	pos($klass_block) = 0;

	if (!exists $$klass_to_methods{$klass_name})
	{
	    $$klass_to_methods{$klass_name} = undef;
	}

	while($klass_block =~ m/\s*(method)\s+(.*?)\s*($rk)\s*($main::list)\s*(.*?)\s*;/gc)
	{
	    my $method_name = &normalize_signature("$2 $3$4");
	    my $throw_spec  = $5;
	    $$root{$klass_type}{$klass_name}{'methods'}{$method_name} = undef;
	    $$klass_to_methods{$klass_name}{$method_name} = undef;

	    if($method_name =~ m|^va:|)
	    {
		# assumption: $alias_name also begins with "va:"
		$$va_methods{"$klass_name:$method_name"} = undef;
		$$va_generics{"dk:$method_name"} = undef;
		my $method_name_xxx = $method_name;
		$method_name_xxx =~ s|^va:||;
		$$generic_to_methods{"dk:$method_name_xxx"}{"$klass_name:$method_name"} = undef;
	    }
	}
	pos($klass_block) = 0;

	while($klass_block =~ /\s*(method)\s+(.*?)\s*($rk)\s*($main::list)\s*(.*?)\s*($main::block)/gc)
	{
	    my $return_type  = $2;
	    my $method_name  = &normalize_signature("$2 $3$4\{\}");
	    my $method_args  = $4;
	    my $throw_spec   = $5;
	    my $method_block = $6;

	    $$klass_to_methods{$klass_name}{$method_name} = undef;

	    $$method_to_generics{$klass_type}{$klass_name}{$method_name} = {};
	    $$generic_to_methods{"dk:$method_name"}{"$klass_name:$method_name"} = undef;
	    
	    if($method_name =~ m|^va:|)
	    {
		my $method_name_xxx = $method_name;
		$method_name_xxx =~ s|^va:||;
		$$va_methods{"$klass_name:$method_name"} = undef;
		$$va_generics{"dk:$method_name"} = undef;
		$$generic_to_methods{"dk:$method_name_xxx"}{"$klass_name:$method_name"} = undef;

		if(!exists $$generic_to_klasses{"dk:$method_name_xxx"})
		{
		    $$generic_to_klasses{"dk:$method_name_xxx"} = {};
		}
		$$generic_to_klasses{"dk:$method_name_xxx"}{"$klass_name"} = undef;
	    }
	    if(!exists $$generic_to_klasses{"dk:$method_name"})
	    {
		$$generic_to_klasses{"dk:$method_name"} = {};
	    }
	    $$generic_to_klasses{"dk:$method_name"}{"$klass_name"} = undef;
	}
    }
}
#print Dumper $method_to_generics;
#print Dumper $generic_to_methods;
#print STDERR &Dumper($klass_to_superklass);
#print STDERR &Dumper($klass_to_methods);
#print STDERR &Dumper($root);

my $nodes = '';
my $klass_names = [keys %$klass_to_methods];
foreach my $klass_name (sort @$klass_names)
{
    if (exists $$klasses{$klass_name} || exists $$traits{$klass_name})
    {
    $nodes .= "\t\"$klass_name\" \[\n";
    $nodes .= "\t\tlabel =\n";
    $nodes .= "\t\t\t<\n";
    $nodes .= "\t\t\t<table>\n";
    $nodes .= "\t\t\t\t<tr><td align=\"center\" port=\"name\">$klass_name</td></tr>\n";
    if (!defined $$opts{simple})
    {
	my $methods = $$klass_to_methods{$klass_name};
	if ($methods)
	{
	my @keys = keys %$methods;
	my $key;
	foreach $key (sort method::compare @keys)
	{
	    $nodes .= "\t\t\t\t<tr><td align=\"left\">$key</td></tr>\n";
	}
	}
    }
    $nodes .= "\t\t\t</table>\n";
    $nodes .= "\t\t\t>\n";
    $nodes .= "\t\];\n";
    }
}
$nodes .= "\n";

my $edges = '';

my ($va_method, $dummy1);
while(($va_method, $dummy1) = each %$va_methods)
{
    my $method_xxx = $va_method;
    $method_xxx =~ s|:va:|:|;
    $edges .= "\t\"$method_xxx\" \[ color = grey \];\n";
    $edges .= "\t\"$method_xxx\" -> \"$va_method\";\n";
    $edges .= "\t{ rank = same; \"$method_xxx\"; \"$va_method\"; };\n";
}

my ($va_generic, $dummy2);
while(($va_generic, $dummy2) = each %$va_generics)
{
    my $generic_xxx = $va_generic;
    $generic_xxx =~ s|:va:|:|;
    $edges .= "\t\"$generic_xxx\" -> \"$va_generic\";\n";
    $edges .= "\t{ rank = same; \"$generic_xxx\"; \"$va_generic\"; };\n";
}
#$edges .= "\t\"dk:make\" \[ color = grey \];\n";
#$edges .= "\t\"dk:alloc\" \[ color = grey \];\n";
#$edges .= "\t\"dk:init\" \[ color = grey \];\n";
#$edges .= "\t\"dk:make\" -> { \"dk:alloc\"; \"dk:init\" };\n";

my $name_port = ':name';

foreach my $klass_name (sort keys %$klass_to_superklass)
{
    my $superklass_name = $$klass_to_superklass{$klass_name};

    if (exists $$klasses{$superklass_name})
    {
        $edges .= "\t\"$superklass_name\"$name_port -> \"$klass_name\"$name_port \[ dir = back \];\n";
    }
    else
    {
        #$edges .= "\t\"$superklass_name\" -> \"$klass_name\"$name_port \[ dir = back \];\n";
    }
}
$edges .= "\n";

foreach my $klass_name (sort keys %$klass_to_traits)
{
    foreach my $trait_name (sort keys %{$$klass_to_traits{$klass_name}})
    {
	if (exists $$traits{$trait_name})
	{
	    $edges .= "\t\"$trait_name\"$name_port -> \"$klass_name\"$name_port \[ dir = back, style = dashed \];\n";
	}
	else
	{
	    #$edges .= "\t\"$trait_name\" -> \"$klass_name\"$name_port \[ dir = back, style = dashed \];\n";
	}
    }
}

my $page_width  =  8.5;
my $page_height = 11;

#my $page_width  = 11;
#my $page_height = 17;

# 0.5 in margins
my $size_width  = 1 * (- 0.5 + $page_width  - 0.5);
my $size_height = 1 * (- 0.625 + $page_height - 0.625);

my $shape = 'plaintext';

print "digraph dg\n\{\n";
print "\tgraph \[ rankdir = LR \];\n";
print "\tgraph \[ size = \"$size_width,$size_height\" \];\n";
print "\tgraph \[ page = \"$page_width,$page_height\" \];\n";
print "\tgraph \[ fontname = courier \];\n";
if (!defined $$opts{simple})
{
    print "\tgraph \[ ratio = fill \];\n";
}
#print "\tgraph \[ rotate = 90 \];\n";
print "\tnode \[ shape = $shape \];\n";
print "\n";
print $nodes;
print "\n";
print $edges;
print "}\n";
