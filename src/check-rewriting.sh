#!/bin/bash

paths=$(echo build/*/+user/*.cc)
for ccfile in $paths; do
    base=$(basename $ccfile .dk.cc)
    dkfile="$base.dk"
    dkfile_lines=($(wc -l $dkfile))
    ccfile_lines=($(wc -l $ccfile))
    dkfile_lines=${dkfile_lines[0]}
    ccfile_lines=${ccfile_lines[0]}
    if (( $dkfile_lines != $ccfile_lines - 1 )); then
        echo "WARNING: rewriting modified the number of lines in traslation unit: $dkfile: $dkfile_lines != $ccfile_lines - 1"
    fi
done
