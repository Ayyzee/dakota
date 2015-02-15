#!/bin/bash

set -o nounset -o errexit -o pipefail

echo "$1: \\"

for exe_src_path in should-pass/*/exe.dk; do
    dir=$(dirname $exe_src_path)
    echo " $dir/exe \\"
done
