#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
export DKT_EXCLUDE_LIBS=2
cmake --build $dir --target install
