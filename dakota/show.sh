#!/bin/bash
set -o errexit -o nounset -o pipefail

build_dir=build/dkt

cat $build_dir/dakota.io

if [[ -d $build_dir ]]; then
    {
        find $build_dir  -name "*.h"
        find $build_dir  -name "*.cc"
        find $build_dir  -name "*.inc"
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
