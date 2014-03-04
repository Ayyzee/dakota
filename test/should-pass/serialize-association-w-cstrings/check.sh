#!/bin/sh -u

./exe > out.pl
./gen-object-graph.pl out.pl > out.dot
#open out.dot
