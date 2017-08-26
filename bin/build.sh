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
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON
generator="${generator:-ninja}"
SECONDS=0
$generator -C $binary_dir -j $jobs $@
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
