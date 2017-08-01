#!/bin/bash
set -o errexit -o nounset -o pipefail
remove-binary-dir() {
  if [[ -e ../cmake-binary-dir.txt ]]; then
    binary_dir=$(cat ../cmake-binary-dir.txt)
  else
    binary_dir=build-cmk
  fi
  rm -fr $binary_dir
}
rootdir=..
$rootdir/bin/build-uninstall.sh
remove-binary-dir
rm -fr build-dkt
$rootdir/bin/cmake-configure.sh
$rootdir/bin/build.sh $@
