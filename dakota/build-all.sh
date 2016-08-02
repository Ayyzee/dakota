#!/bin/bash
set -o errexit -o nounset -o pipefail
IFS=$'\t\n'

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
jobs=$(getconf _NPROCESSORS_ONLN)
jobs=1
export DKT_EXCLUDE_LIBS=2
time cmake --build $dir --target init
time cmake --build $dir -- --jobs $jobs
