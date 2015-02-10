#!/bin/bash

set -o nounset -o errexit -o pipefail #-o xtrace

so_ext=dylib

libs="\
 ../lib/libdakota.$so_ext\
 ../lib/libdakota-util.$so_ext"

tmp=/tmp/$(basename $0)-$$.txt
cat /dev/null > $tmp

for lib in $libs; do
    if [[ -e $lib ]]; then
        lib_bname=$(basename $lib)
        bin/nm.sh $lib | tee $lib_bname
        echo -n "defined external symbols: " >> $tmp
        wc -l $lib_bname >> $tmp
        mv $lib_bname /tmp
    fi
done
#echo "defined external symbols:"
cat $tmp
