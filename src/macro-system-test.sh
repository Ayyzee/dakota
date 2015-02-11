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

    if ! diff $path macro-system-test-output/$name.cc; then
        /bin/echo "---"
        echo "diff $path macro-system-test-output/$name.cc"
        diff $path macro-system-test-output/$name.cc || true
        echo "wc -l $path macro-system-test-output/$name.cc"
        wc -l $path
        wc -l macro-system-test-output/$name.cc
    fi
done
