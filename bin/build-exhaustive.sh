#!/bin/bash
set -o errexit -o nounset -o pipefail
remove-build-dir() {
  if [[ -e .build-dir.txt ]]; then
    build_dir=$(cat .build-dir.txt)
  else
    build_dir=zzz/build
  fi
  rm -fr $build_dir
}
rootdir=..
$rootdir/bin/build-uninstall.sh
remove-build-dir
rm -fr build/dkt
$rootdir/bin/cmake-configure.sh
$rootdir/bin/build.sh $@
