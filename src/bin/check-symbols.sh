#!/bin/bash

set -o nounset -o errexit -o pipefail #-o xtrace

so_ext=dylib

libs="\
 ../lib/libdakota.$so_ext\
 ../lib/libdakota-util.$so_ext"

mkdir -p check-history
output=check-history/$(basename $0)-$$.txt
rm -f $output
touch $output

{
for lib in $libs; do
    if [[ -e $lib ]]; then
        lib_bname=$(basename $lib)
        bin/nm.pl $lib | tee $lib_bname
        echo -n "defined external symbols: "
        wc -l $lib_bname
        mv $lib_bname /tmp
    fi
done
} > $output
#echo "defined external symbols:"
cat $output
