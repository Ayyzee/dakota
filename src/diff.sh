#!/bin/bash

set -o nounset -o errexit -o pipefail

for path in $@; do
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
