#!/usr/bin/perl -w

use strict;
use warnings;

sub ident_regex {
  my $id =  qr/  [_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9]               )?/x;
  my $mid = qr/  [_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?\!])|(?:[\?\!]) /x; # method id
  my $bid = qr/  [_a-zA-Z](?:[_a-zA-Z0-9-]*[_a-zA-Z0-9\?]  )|(?:[\?]  ) /x; # boole  id
  my $tid = qr/  [_a-zA-Z]   [_a-zA-Z0-9-]*?-t/x;                           # type   id
  my $gf_prefix = qr/dk::|\$/;

  # symbol  id:           $id
  # keyword id:           $mid
  # method id suffix opt: \?|\!
  # boole id suffix:      \?

  my $sco = qr/::/x; # scope resolution operator
  my $rid =  qr/(?:$id$sco?)*$id/;  # relative id
  my $rmid = qr/(?:$id$sco?)*$mid/; # relative mid
  my $rbid = qr/(?:$id$sco?)*$bid/; # relative bid
  my $rtid = qr/(?:$id$sco?)*$tid/; # relative tid

  return ( $id,  $mid,  $bid,  $tid,
          $rid, $rmid, $rbid, $rtid, $gf_prefix);
}
my ($id,  $mid,  $bid,  $tid,
   $rid, $rmid, $rbid, $rtid, $gf_prefix) = &ident_regex();

sub rewrite_supers {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/($gf_prefix$mid\s*)\(\s*super\b/$1(super(self, klass)/g;
  $$filestr_ref =~ s/(va::$gf_prefix$mid\s*)\(\s*super\b/$1(super(self, klass)/g;
}
sub rewrite_generic_function_calls {
  my ($filestr_ref) = @_;
  $$filestr_ref =~ s/\$($mid\s*)\(/dk::$1\(/gs;
}

undef $/;
my $filestr = <STDIN>;
&rewrite_generic_function_calls(\$filestr);
&rewrite_supers(\$filestr);
print $filestr;
