#!/usr/bin/perl -w

use strict;

# throw $"..." ;
# throw $[...] ;
# throw ${...} ;
# throw box(...) ;
# throw klass ;
# throw make(...) ;
# throw self ;
#
# throw-object ... ;

# and all of the above with RHS in ()

# todo:
#   throw xx:yy:box(...) ;

sub gen_throw_object_statements
{
    my $lhss = [ 'throw', 'throw-object' ];
    my $rhss = [ '$"..."', '$[...]', '${...}', 'box(...)', 'klass', 'make(...)', 'self' ];

    foreach my $lhs (@$lhss)
    {
	foreach my $in_parens (0, 1)
	{
	    foreach my $rhs (@$rhss)
	    {
		print "$lhs";
		if ($in_parens) { print '('; } else { print ' '; }
		print "$rhs";
		if ($in_parens) { print ')'; }
		print ";\n";
	    }
	}
    }
}

sub gen_throw_str_statements
{
    my $lhss = [ 'throw', 'throw-str' ];
    my $rhss = [ '"foo bar"', '$foo-bar' ];

    foreach my $lhs (@$lhss)
    {
	foreach my $in_parens (0, 1)
	{
	    foreach my $rhs (@$rhss)
	    {
		print "$lhs";
		if ($in_parens) { print '('; } else { print ' '; }
		print "$rhs";
		if ($in_parens) { print ')'; }
		print ";\n";
	    }
	}
    }
}

&gen_throw_object_statements();
&gen_throw_str_statements();
