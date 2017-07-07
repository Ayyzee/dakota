#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
cmake $extra_opts --build $dir --target clean
