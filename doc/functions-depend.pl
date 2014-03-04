#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $__selector_alloc   = '__selector:alloc(object-t)';
my $__signature_alloc = '__signature:alloc(object-t)';

my $klass_alloc_user = 'klass:alloc(object-t)';
#my $klass_alloc  = 'klass:alloc(object-t, keyword-t, ...)';
#my $range_va_alloc = 'range:va:alloc(object-t, keyword-t, va-list-t)';
my $dk_alloc_object = 'dk:alloc(object-t)';
my $dk_alloc_super  = 'dk:alloc(super-t)';
#my $dk_va_alloc_object = 'dk:va:alloc(object-t, keyword-t, va-list-t)';
#my $dk_va_alloc_super  = 'dk:va:alloc(super-t, keyword-t, va-list-t)';

my $klass_alloc_graph = {
#    $__selector_alloc =>
#        [
#         $__signature_alloc 
#        ],
#    $__signature_alloc =>
#        [
#        ],
   $dk_alloc_object =>
        [
         $klass_alloc_user
        ],
   $klass_alloc_user =>
        [
          $dk_alloc_super
        ],
#   $dk_va_alloc_object =>
#        [
#          $__selector_alloc,
#          $__signature_alloc,
#          $range_va_alloc
#        ],
#   $dk_va_alloc_super =>
#        [
#          $__selector_alloc,
#          $__signature_alloc,
#          $range_va_alloc
#        ],
#   'dk:make(object-t, keyword-t, ...)' =>
#        [
#          $dk_alloc_object
#        ],
#   $range_va_alloc =>
#        [
#          $klass_alloc_user
#        ],
#   $klass_alloc =>
#        [
#          $range_va_alloc
#        ],
};

my $__selector_va_init   = '__selector:va:init(object-t, keyword-t, va-list-t)';
my $__signature_va_init = '__signature:va:init(object-t, keyword-t, va-list-t)';

my $range_init_user = 'range:init(object-t, int32-t $max, int32-t $min = 0)';
my $range_init  = 'range:init(object-t, keyword-t, ...)';
my $range_va_init = 'range:va:init(object-t, keyword-t, va-list-t)';
my $dk_init_object = 'dk:init(object-t, keyword-t, ...)';
my $dk_init_super  = 'dk:init(super-t, keyword-t, ...)';
my $dk_va_init_object = 'dk:va:init(object-t, keyword-t, va-list-t)';
my $dk_va_init_super  = 'dk:va:init(super-t, keyword-t, va-list-t)';

my $dk_va_make = 'dk:va:make(object-t, keyword-t, va-list-t)';
my $dk_make = 'dk:make(object-t, keyword-t, ...)';

my $range_init_graph = {
    $__selector_va_init =>
        [
         $__signature_va_init 
        ],
    $__signature_va_init =>
        [
        ],
   $dk_init_super =>
        [
          $__selector_va_init,
          $__signature_va_init,
          $dk_va_init_super
        ],
   $dk_init_object =>
        [
          $__selector_va_init,
          $__signature_va_init,
          $dk_va_init_object
        ],
   $range_init_user =>
        [
         $dk_make
        ],
   $dk_va_init_object =>
        [
          $__selector_va_init,
          $__signature_va_init
        ],
   $dk_va_init_super =>
        [
          $__selector_va_init,
          $__signature_va_init
        ],
   $range_va_init =>
        [
          $range_init_user
        ],
   $range_init =>
        [
          $range_va_init
        ],
};

my $dk_make_graph =
{
   $dk_make =>
        [
          #$dk_alloc_object,
          $dk_init_object,
          $dk_va_make
        ],
   $dk_va_make =>
        [
          $dk_va_init_object
        ],
};

#print(Dumper($range_init));

print "digraph functions\n";
print "{\n";

#print "  graph [ rankdir = LR, center = true, size = \"10,7.5\", rotate = 90 ];\n";
print "  graph [ rankdir = TB, center = true, size = \"7.5,10\" ];\n";
print "  node [ shape = box ];\n";
print "  edge [ dir = back ];\n";

my $key;
my $vals;

while(($key, $vals) = each(%$klass_alloc_graph))
{
    my $val;
    foreach $val (@$vals)
    {
        #print "  \"$key\"  ->  \"$val\";\n";
    }
}

while(($key, $vals) = each(%$range_init_graph))
{
    my $val;
    foreach $val (@$vals)
    {
        #print "  \"$key\"  ->  \"$val\";\n";
        #print "  \"$val\"  ->  \"$key\";\n";
        print "\n";
        print "   \"$val\"\n";
        print "-> \"$key\";\n";
    }
}

while(($key, $vals) = each(%$dk_make_graph))
{
    my $val;
    foreach $val (@$vals)
    {
        #print "  \"$key\"  ->  \"$val\";\n";
        print "\n";
        print "   \"$val\"\n";
        print "-> \"$key\";\n";
    }
}

print "\n";
#print "\"$klass_alloc_user\" [ color = grey ];\n";
print "\"$range_init_user\"  [ color = grey ];\n";
print "\n";
#print "  { rank = same; \"$dk_alloc_super\"; \"$dk_init_super\"; }\n";
#print "  { rank = same; \"$dk_alloc_object\"; \"$dk_init_object\"; }\n";
#print "  { rank = same; \"$klass_alloc_user\"; \"$range_init_user\"; }\n";
print "}\n";
