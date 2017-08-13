#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e ../cmake-binary-dir.txt ]]; then
  binary_dir=$(cat ../cmake-binary-dir.txt)
else
  binary_dir=build-cmk
fi
jobs=$(getconf _NPROCESSORS_ONLN)
jobs=$(( jobs + 2 ))

if [[ -e jobs.txt ]]; then
  jobs=$(cat jobs.txt)
fi
generator="${generator:-ninja}"
DAKOTA_VERBOSE=1 $generator -C $binary_dir -j $jobs $@
