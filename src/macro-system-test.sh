#!/bin/bash

set -o nounset -o errexit -o pipefail

if [[ 0 == $# ]]; then
    paths=$(echo *.dk)
else
    paths=$@    
fi

prefix=..
default_macros_path=$prefix/lib/dakota/macros.pl

DKT_MACROS_DEBUG=0 DK_MACROS_PATH=${DK_MACROS_PATH=$default_macros_path} $prefix/lib/dakota/macro_system.pm $paths > /tmp/summary-$$.txt

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
