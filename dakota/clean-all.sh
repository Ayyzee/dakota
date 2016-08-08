#!/bin/bash
IFS=$'\t\n'
set -o errexit -o nounset -o pipefail

if [[ -e Makefile ]]; then
  make clean || true
fi
./cmake-clean.sh
dakota-build2project dakota.build dakota.project
dakota-build2cmk dakota.project dakota.cmk
#
dir=.
cmake -Wdev $dir
#
./build-clean.sh $dir
echo +++
./build-all.sh $dir
#
echo +++
./show.sh
