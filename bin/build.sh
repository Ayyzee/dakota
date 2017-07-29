#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e ../cmake-binary-dir.txt ]]; then
  binary_dir=$(cat ../cmake-binary-dir.txt)
else
  binary_dir=build-cmk
fi
jobs=$(getconf _NPROCESSORS_ONLN)
make --directory $binary_dir --jobs $jobs $@
