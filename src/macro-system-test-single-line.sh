#!/bin/bash

set -o nounset -o errexit -o pipefail

if [[ 0 == $# ]]; then
    path=literal-syntax-single-line.dk
else
    path=$1 # ignore other command line args
fi

prefix=..
default_macros_path=$prefix/lib/dakota/macros.pl

DK_MACROS_SINGLE_LINE=1 DKT_MACROS_DEBUG=0 DK_MACROS_PATH=${DK_MACROS_PATH=$default_macros_path} $prefix/lib/dakota/macro_system.pm $path > /tmp/summary-$$.txt
