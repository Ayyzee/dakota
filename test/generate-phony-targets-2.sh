#!/bin/bash

set -o nounset -o errexit -o pipefail

echo "$1:"

for exe_src_path in should-pass/*/exe.dk; do
    printf "\t\$(MAKE) --directory %s \$@\n" $(dirname $exe_src_path)
done
