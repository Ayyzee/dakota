#!/bin/sh -u

g++ -Wall -g3 -o gen-ops gen-ops.cc
./gen-ops > ops.txt
sort -o ops.txt ops.txt
cat ops.txt
