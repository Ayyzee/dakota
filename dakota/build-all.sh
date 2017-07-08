#!/bin/bash
set -o errexit -o nounset -o pipefail
dir=$(cat cmake-build-dir.txt)
jobs=$(getconf _NPROCESSORS_ONLN)
cmake --build $dir --target init
cmake --build $dir --target all -- --jobs $jobs
