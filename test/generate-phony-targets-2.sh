#!/bin/bash

set -o nounset -o errexit -o pipefail

echo "$1:"

for exe_src_path in $2/*/exe.dk; do
    printf "\t\$(MAKE) --directory %s \$@ || touch failed-execute\n" $(dirname $exe_src_path)
done
