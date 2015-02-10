#!/bin/bash

set -o nounset -o errexit -o pipefail

if [[ 0 == $# ]]; then
    paths="macro-system-test.dk"
else
    paths="$@"    
fi

DK_MACROS_PATH=macro-system-test-input.pl DK_PREFIX=.. ../lib/dakota/macro_system.pm $paths

for path in $paths; do
    name=$(basename $path)
    /bin/echo "---"
    echo "diff $path macro-system-test-output/$name"
    diff $path macro-system-test-output/$name.cc || true
    echo "wc -l $path macro-system-test-output/$name"
    wc -l $path macro-system-test-output/$name.cc
done
