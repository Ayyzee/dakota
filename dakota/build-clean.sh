#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=$(cat cmake-build-dir.txt)
extra_opts=
cmake $extra_opts --build $dir --target clean
