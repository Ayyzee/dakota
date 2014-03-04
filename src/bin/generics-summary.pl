#!/usr/bin/perl -w

use strict;

use Data::Dumper;

undef $/;

my $str = <STDIN>;
my $data = eval $str;

my $generics = {};

#print &Dumper($data);

my ($klass_name, $klass_scope);
while (($klass_name, $klass_scope) = each (%$data))
{
    my ($method_sig, $method_scope);
    while (($method_sig, $method_scope) = each %{$$klass_scope{'methods'}})
    {
	delete $$method_scope{'defined?'};
	my $proto = &signature($method_scope);
	if (!$$generics{$proto})
	{
	    $$generics{$proto} = $method_scope; 
	}
	$$generics{$proto}{'klass-names'}{$klass_name} = undef;
    }
}
#print &Dumper($generics);
my $generics_seq = [sort method::compare values %$generics];
#print &Dumper($generics_seq);

# padding width determination pass
my $max_width = 0;
foreach my $scope (@$generics_seq)
{
    my $width = length($$scope{'return-type'});
    if ($width > $max_width)
    { $max_width = $width; }
}

foreach my $scope (@$generics_seq)
{
    my $width = length($$scope{'return-type'});
    my $pad = ' ' x ($max_width - $width);
    my $count = keys %{$$scope{'klass-names'}};

    printf("%s%s %s(%s); // -%i-\n",
	   $$scope{'return-type'},
	   $pad,
	   $$scope{'name'},
	   $$scope{'parameter-types'},
	   $count);
}

# technically a "signature" only include the 'name' and 'parameter-types', not the 'return type'
# but to catch generics that differ only in 'return-type' (and thus won't compile) we
# need to include 'return-type'
sub signature
{
    my ($scope) = @_;
    my $result = "$$scope{'name'}($$scope{'parameter-types'}) $$scope{'return-type'}";
    return $result;
}

sub method::compare
{
    my $a_string = &signature($a);
    my $b_string = &signature($b);
    return $a_string cmp $b_string;
}
