#!/bin/bash

set -o nounset -o errexit -o pipefail

if [[ 0 == $# ]]; then
    paths="macro-system-test.dk"
else
    paths="$@"    
fi

rootdir=..
DK_PREFIX=$rootdir
default_macros_path=$DK_PREFIX/lib/dakota/macros.pl

DK_MACROS_PATH=${DK_MACROS_PATH=$default_macros_path} DK_PREFIX=$DK_PREFIX $DK_PREFIX/lib/dakota/macro_system.pm $paths > /tmp/summary-$$.txt 2>&1

for path in $paths; do
    name=$(basename $path)

    if ! diff --brief $path macro-system-test-output/$name.cc > /dev/null; then
        echo "diff $path macro-system-test-output/$name.cc"
        diff $path macro-system-test-output/$name.cc || true
        echo "wc -l $path macro-system-test-output/$name.cc"
        wc -l $path
        wc -l macro-system-test-output/$name.cc
        /bin/echo "***"
    fi
done

cat /tmp/summary-$$.txt
rm /tmp/summary-$$.txt
