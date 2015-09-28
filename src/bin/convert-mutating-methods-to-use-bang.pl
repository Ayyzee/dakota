#!/usr/bin/perl -w

use strict;
use warnings;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Sortkeys = 1;

my $num_args = scalar @ARGV;
my $name = $0;
$name =~ s|^.*/||;
$name =~ s|\..*$||;
my $outfile = "/tmp/$name.pl";
if ($num_args) {
    my @args = @ARGV;
    my $methods = { 'args' => \@args, 'methods' => {}};
    while (<>) {
        # add*
        # remove*
        # empty
        # push
        # pop
        # set-bit
        # set-key
        # set-element
        while ($_ =~ m/\bmethod\b.+((add|remove|empty|set-bit|set-key|set-element|reverse|replace)[\w-]*)\(/g) {
            if ($1 !~ m/\!$/) {
                #print $1 . "\n";
                $$methods{'methods'}{$1} = 1;
            }
        }
    }
    open(OUT, ">$outfile") or die;
    print OUT &Dumper($methods);
    close OUT;
    print "wrote $outfile\n";
} else {
    print "read $outfile\n";
    my $out = do $outfile or die;
    foreach my $method (sort keys %{$$out{'methods'}}) {
        my $cmds = [
            # ?ident (
            sprintf("/usr/bin/perl -p -i -e 's/\\b\%s\\(/\%s!\\(/g'", $method, $method),
            # alias ( ?ident )
            sprintf("/usr/bin/perl -p -i -e 's/\\balias\\s*\\(\\s*\%s\\s*\\)/alias\\(\%s!\\)/g'", $method, $method),
            # selector ( ?ident ,
            sprintf("/usr/bin/perl -p -i -e 's/\\bselector\\s*\\(\\s*\%s\\s*\\(/selector\\(\%s!\\(/g'", $method, $method),
            ];
        foreach my $cmd (@$cmds) {
            my @args = ( $cmd, @{$$out{'args'}} );
            print "$cmd ...\n"; #print &Dumper($$out{'args'});
            system("@args") == 0 or die;
        }
    }
}
# remove-items()
