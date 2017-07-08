#!/bin/bash
set -o errexit -o nounset -o pipefail

builddir=dkt

cat $builddir/dakota.io

if [[ -d $builddir ]]; then
    {
        find $builddir  -name "*.h"
        find $builddir  -name "*.cc"
        find $builddir  -name "*.inc"
    } | sort
fi
if [[ -d CMakeFiles ]]; then
    find CMakeFiles -name "*.o"  | sort
fi
if [[ -d cm ]]; then
    find cm -name "*.o"  | sort
fi

{
    find . -name "*.so"
    find . -name "*.dylib"
} | sort
