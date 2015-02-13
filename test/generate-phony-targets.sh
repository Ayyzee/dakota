#!/bin/bash

set -o nounset -o errexit -o pipefail

exe_src_paths=should-pass/*/exe.dk

echo "$1: \\"

for exe_src_path in $exe_src_paths; do
    dir=$(dirname $exe_src_path)
    echo " $dir/exe \\"
done

echo

echo "$2 $3:"

for exe_src_path in should-pass/*/exe.dk; do
    printf "\t\$(MAKE) --directory %s \$@\n" $(dirname $exe_src_path)
done
