#!/bin/bash
set -o errexit -o nounset -o pipefail
dir=$(cat cmake-build-dir.txt)
./cmake-clean.sh
./cmake-configure.sh $dir
./build-clean.sh
./build-all.sh

