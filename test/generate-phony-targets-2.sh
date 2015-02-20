#!/bin/bash

set -o nounset -o errexit -o pipefail

source common.sh

dk_paths=$(paths-from-pattern "$2/*/exe.dk")
cc_paths=$(paths-from-pattern "$2/*/exe.cc")

echo "$1:"

for exe_src_path in $dk_paths $cc_paths; do
    dir=$(dirname $exe_src_path)
    printf "\t\$(MAKE) --directory $dir \$@\n"
done
