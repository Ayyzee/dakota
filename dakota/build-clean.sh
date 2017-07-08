#!/bin/bash
set -o errexit -o nounset -o pipefail
dir=$(cat cmake-build-dir.txt)
cmake --build $dir --target clean
