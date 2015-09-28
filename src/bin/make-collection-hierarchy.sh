#!/bin/sh

#bin/make-klass-hierarchy-simple.pl object.dk forward-iterator.dk *set.dk *table.dk *collection.dk > collection.dot && open collection.dot
bin/make-klass-hierarchy-simple.pl object.dk forward-iterator.dk *set.dk *table.dk *collection.dk > collection.dot && open collection.dot

# add vector, deque
