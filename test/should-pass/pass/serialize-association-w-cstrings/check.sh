#!/bin/sh -u

../../../bin/run-with-timeout 3 ./exe > out.pl
./gen-object-graph.pl out.pl > out.dot
#open out.dot
