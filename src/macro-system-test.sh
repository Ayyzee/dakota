#!/bin/bash

set -o nounset -o errexit -o pipefail

start_date=$(date)

if [[ 0 == $# ]]; then
    paths=$(echo *.dk)
else
    paths=$@    
fi

prefix=..
default_macros_path=$prefix/lib/dakota/macros.pl

DKT_MACROS_DEBUG=0 DK_MACROS_PATH=${DK_MACROS_PATH=$default_macros_path} $prefix/lib/dakota/macro_system.pm $paths > /tmp/summary-$$.txt

verbose=false

if $verbose; then
    ./diff.sh $paths > macro-system-test-output/diff.txt
    cat macro-system-test-output/diff.txt
fi

cat /tmp/summary-$$.txt
rm /tmp/summary-$$.txt
echo $start_date
date
