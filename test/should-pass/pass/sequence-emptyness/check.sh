#!/bin/sh -u

../../../bin/run-with-timeout 3 ./exe &> out
./wrap.sh out
#make $1.dot.ps
#open $1.dot
