#!/bin/bash
IFS=$'\t\n'
set -o errexit -o nounset -o pipefail

if [[ -e Makefile ]]; then
  make clean || true
fi
./cmake-clean.sh
#
dir=.
cmake -Wdev $dir
#
./build-clean.sh $dir
./build.sh $dir
