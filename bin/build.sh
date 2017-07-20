#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=$(cat cmake-binary-dir.txt)
target=all
if [[ 1 == $# ]]; then
  target=$1
fi
jobs=$(getconf _NPROCESSORS_ONLN)
echo ++$target++
cmake --build $binary_dir --target $target -- --jobs $jobs
