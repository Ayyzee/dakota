#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=$(cat cmake-build-dir.txt)
target=all
if [[ 1 == $# ]]; then
  target=$1
fi
jobs=$(getconf _NPROCESSORS_ONLN)
export DKT_EXCLUDE_LIBDAKOTA=1
echo ++init++
cmake --build $dir --target init
echo ++default++
cmake --build $dir --target $target -- --jobs $jobs
