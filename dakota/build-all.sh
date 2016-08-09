#!/bin/bash
set -o errexit -o nounset -o pipefail
IFS=$'\t\n'

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
jobs=$(getconf _NPROCESSORS_ONLN)
#jobs=1
export DKT_EXCLUDE_LIBS=2
echo ++init++
cmake --build $dir --target init
echo ++default++
cmake --build $dir -- --jobs $jobs
