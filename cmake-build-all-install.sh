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

build() {
  dir=$1
  cd $dir
  cwd=$(pwd)
  echo cwd=$cwd
  rootdir=..
  $rootdir/bin/build-exhaustive.sh
  $rootdir/bin/build.sh install
  cd ..
}
export PATH=$INSTALL_PREFIX/bin:$PATH
export CMAKE_VERBOSE_MAKEFILE=ON

./bin/build-uninstall.sh $INSTALL_PREFIX
warning=
if [[ $INSTALL_PREFIX != "/usr/local" && -e /usr/local/bin/dakota ]]; then
  warning="$(basename $0): warning: installation also in /usr/local"
  echo $warning
fi

# dakota-dso dakota-catalog dakota-find-library
# dakota-core dakota

build dakota-dso
build dakota-catalog
build dakota-find-library

build dakota-core

pushd $INSTALL_PREFIX/lib/dakota
ln -fs compiler-command-line-$compiler.json compiler-command-line.json
ln -fs platform-$platform.json platform.json
popd

build dakota
echo $warning
