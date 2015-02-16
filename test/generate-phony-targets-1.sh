#!/bin/bash

set -o nounset -o errexit -o pipefail

echo "$1: \\"

for exe_src_path in $2/*/exe.dk; do
    dir=$(dirname $exe_src_path)
    echo " $dir/exe \\"
done
