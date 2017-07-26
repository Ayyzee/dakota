#!/bin/bash
set -o errexit -o nounset -o pipefail
source common.sh
compiler=$(compiler)
platform=$(platform)
CMAKE_INSTALL_PREFIX=$HOME
if [[ $# == 1 ]]; then
  CMAKE_INSTALL_PREFIX=$1
fi
export CMAKE_INSTALL_PREFIX
INSTALL_PREFIX=$CMAKE_INSTALL_PREFIX

build-all-install() {
  dir=$1
  pushd $dir
  echo cwd=$dir
  rootdir=..
  $rootdir/bin/cmake-clean.sh
  #
  $rootdir/bin/cmake-configure.sh
  $rootdir/bin/build-clean.sh
  $rootdir/bin/build-all.sh ###
  $rootdir/bin/build-install.sh
  popd
}
build-all-install-dk() {
  dir=$1
  pushd $dir
  echo cwd=$dir
  rootdir=..
  $rootdir/bin/cmake-clean.sh
  rm -f dakota.cmake # hackhack
  $rootdir/bin/cmake-configure.sh
  $rootdir/bin/build-clean.sh
  $rootdir/bin/build-all-dk.sh ###
  $rootdir/bin/build-install.sh
  popd
}

export PATH=$INSTALL_PREFIX/bin:$PATH
export CMAKE_VERBOSE_MAKEFILE=ON

finish() {
  find $INSTALL_PREFIX/lib -name "libdakota*" -type f | sort
  if [[ -e $INSTALL_PREFIX/lib/dakota ]]; then
    find $INSTALL_PREFIX/lib/dakota -type f | sort
  fi
  find $INSTALL_PREFIX/bin -name "dakota*" -type f | sort
}
if false; then
  trap finish EXIT
fi
#exit

./bin/dakota-build-uninstall.sh $INSTALL_PREFIX

# dakota-dso dakota-catalog dakota-find-library
# dakota-core dakota

build-all-install    dakota-dso
build-all-install    dakota-catalog
build-all-install    dakota-find-library

build-all-install-dk dakota-core

pushd $INSTALL_PREFIX/lib/dakota
ln -fs compiler-command-line-$compiler.json compiler-command-line.json
ln -fs platform-$platform.json platform.json
popd

build-all-install-dk dakota
