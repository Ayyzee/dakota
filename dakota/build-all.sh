#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=$(cat cmake-binary-dir.txt)
jobs=$(getconf _NPROCESSORS_ONLN)
cmake --build $binary_dir --target init
cmake --build $binary_dir --target all -- --jobs $jobs
