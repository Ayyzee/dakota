#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=$(cat cmake-build-dir.txt)
jobs=$(getconf _NPROCESSORS_ONLN)
export DKT_EXCLUDE_LIBDAKOTA=1
echo ++init++
cmake --build $dir --target init
echo ++default++
cmake --build $dir --target all -- --jobs $jobs
