#!/bin/bash

set -o errexit -o nounset -o pipefail

source bin/common.sh

dk_paths=$(paths-from-pattern "$1/*/exe-main.dk")
cc_paths=$(paths-from-pattern "$1/*/exe-main.cc")

for exe_src_path in $dk_paths; do
    dir=$(dirname $exe_src_path)
    echo "$dir/exe"
done
for exe_src_path in $cc_paths; do
    dir=$(dirname $exe_src_path)
    echo "$dir/exe-cc"
done
