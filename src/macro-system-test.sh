#!/bin/bash

set -o nounset -o errexit -o pipefail


if [[ 0 == $# ]]; then
    paths=$(echo *.dk)
else
    paths=$@    
fi

prefix=..
default_macros_path=$prefix/lib/dakota/macros.pl

start_date=$(date)
DKT_MACROS_DEBUG=0 DK_MACROS_PATH=${DK_MACROS_PATH=$default_macros_path} $prefix/lib/dakota/macro_system.pm $paths > /tmp/summary-$$.txt
end_date=$(date)

verbose=false

if $verbose; then
    ./diff.sh $paths > /tmp/diff-$$.txt
    cat /tmp/diff-$$.txt
    rm /tmp/diff-$$.txt
fi

cat /tmp/summary-$$.txt
rm /tmp/summary-$$.txt
echo $start_date
echo $end_date
