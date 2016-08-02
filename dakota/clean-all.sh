#!/bin/bash
IFS=$'\t\n'
set -o errexit -o nounset -o pipefail

if [[ -e Makefile ]]; then
  make clean || true
fi
./cmake-clean.sh
dakota-build2project default.project default.build
dakota-build2cmk default.cmk default.project
#
dir=.
cmake -Wdev $dir
#
./build-clean.sh $dir
./build-all.sh $dir
