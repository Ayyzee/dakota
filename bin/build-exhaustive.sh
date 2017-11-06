#!/bin/bash
set -o errexit -o nounset -o pipefail
remove-build-dir() {
  if [[ -e .build-dir.txt ]]; then
    rel_build_dir=$(cat .build-dir.txt)
  else
    rel_build_dir=z/build
  fi
  rm -fr $rel_build_dir
}
rootdir=..
$rootdir/bin/build-uninstall.sh
remove-build-dir
rm -fr $rel_build_dir/../intmd
$rootdir/bin/cmake-configure.sh
$rootdir/bin/build.sh $@
