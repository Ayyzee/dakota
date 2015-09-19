#!/bin/sh -u

./exe &> out
./wrap.sh out
#make $1.dot.ps
#open $1.dot
