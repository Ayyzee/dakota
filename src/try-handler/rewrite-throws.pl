#!/usr/bin/perl -w

use strict;

# throw box(...) ;
# throw xx:yy:box(...) ;
# throw make(...) ;
# throw $"..." ;
# throw $[...] ;
# throw ${...} ;
# throw self ;
# throw klass ;
#
# throw-object ... ;

# and all of the above with RHS in ()

my $k  = qr/[_A-Za-z0-9-]/;
my $z  = qr/[_A-Za-z]$k*[_A-Za-z0-9]?/;

undef $/;
my $filestr = <STDIN>;
my $filestr_ref = \$filestr;

    # throw $"..." ;
    # throw $[...] ;
    # throw ${...} ;
    # throw box(...) ;
    # throw make(...) ;
    # throw klass ;
    # throw self ;
    #
    # not in parens
    $$filestr_ref =~ s/\bthrow(\s*\$\")/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\$\[)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\$\{)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s+box\s*\()/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s+make\s*\()/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s+klass\s*;)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s+self\s*;)/throw-object$1/gs;
    # in parens
    $$filestr_ref =~ s/\bthrow(\s*\(\s*\$\")/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*\$\[)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*\$\{)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*box\s*\()/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*make\s*\()/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*klass\s*\)\s*;)/throw-object$1/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*self\s*\)\s*;)/throw-object$1/gs;
    # add parens if absent
    $$filestr_ref =~ s/\bthrow-object(\s*)(?!\()(.+?);/throw-object($1$2);/gs;

    # throw "...";
    # throw("...");
    # throw $foo-bar;
    # throw($foo-bar);
    $$filestr_ref =~ s/\bthrow(\s*".*?"\s*);/throw-str$1;/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*".*?"\s*\)\s*);/throw-str$1;/gs;
    $$filestr_ref =~ s/\bthrow(\s*\$$z\s*);/throw-str$1;/gs;
    $$filestr_ref =~ s/\bthrow(\s*\(\s*\$$z\s*\)\s*);/throw-str$1;/gs;
    # add parens if absent
    $$filestr_ref =~ s/\bthrow-str(\s*)(?!\()(.+?);/throw-str($1$2);/gs;

print $$filestr_ref;
