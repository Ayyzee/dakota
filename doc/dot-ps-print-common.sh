#!/bin/sh -u

DOT_PS_PRINT_FLAGS=$1
shift

for arg in $@; do
    tmpfile=$arg.ps
    dot -Tps2 $DOT_PS_PRINT_FLAGS -o $tmpfile $arg
    lpr $tmpfile
    rm $tmpfile
done
