#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ -e Makefile ]]; then
  make clean || true
fi

rootdir=..
dir=.

if true; then
  ./cmake-clean.sh
  $rootdir/bin/dakota-build2project dakota.build dakota.project
  $rootdir/bin/dakota-build2cmk dakota.project dakota.cmk
  #
  cmake -Wdev $dir
fi

./build-clean.sh $dir
echo ++build-all++
./build-all.sh $dir
#
#echo ++show++
#./show.sh
