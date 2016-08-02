#!/bin/bash
set -o errexit -o nounset -o pipefail
IFS=$'\t\n'

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
cmake --build $dir --target clean