#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

build-exhaustive() {
  dir=$1
  cd $dir
  cwd=$(pwd)
  echo cwd=$cwd
  rootdir=..
  $rootdir/bin/build-exhaustive.sh
  cd ..
}

./bin/dakota-uninstall.sh /usr/local
./bin/build-uninstall.sh

build-exhaustive dakota-dso
build-exhaustive dakota-catalog
build-exhaustive dakota-find-library
build-exhaustive dakota-core
build-exhaustive dakota
