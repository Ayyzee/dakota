#!/usr/bin/perl -w

use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

# box    klass     <name> export slot   decl
# export trait                   slots  defn
#        interface               method 
my ($col1, $col2, $col3, $col4, $col5, $col6);

my $line = [];

#foreach $col1 ('box', 'export', '')
foreach $col1 ('export', 'noexport')
{
    push @$line, $col1;
    foreach $col2 ('klass', 'trait', 'interface')
    {
        push @$line, $col2;
        foreach $col4 ('export', 'noexport')
        {
            push @$line, $col4;
            foreach $col5 ('slot', 'slots', 'method')
            {
                push @$line, $col5;
                foreach $col6 ('decl', 'defn')
                {
                    push @$line, $col6;
                    &print_line($line);
                    pop @$line;
                }
                #&print_line($line);
                pop @$line;
            }
            #&print_line($line);
            pop @$line;
        }
        #&print_line($line);
        pop @$line;
    }
    #&print_line($line);
    pop @$line;
}

sub print_line
{
    my ($line) = @_;
    my $line_str = "@$line";
    
    if ($line_str =~ m|\bexport\s+(\w+)\s+export\s+(slots)\s+(\w+)|g)
    {
        $line_str .= " # box $1 $2 $3";
    }

    print "$line_str\n";
}
