#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

rm -fr {dakota-dso,dakota-catalog,dakota-core,dakota}/build-{dkt,cmk}
rm -fr build-dkt build-cmk
rm -f jobs.txt

build-exhaustive-in-dir() {
  dir=$1
  cd $dir
  cwd=$(pwd)
  echo cwd=$cwd
  rootdir=..
  $rootdir/bin/build-exhaustive.sh
  cd ..
}

build-exhaustive-in-dir dakota-dso
build-exhaustive-in-dir dakota-catalog
build-exhaustive-in-dir dakota-core
build-exhaustive-in-dir dakota
