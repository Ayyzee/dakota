#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  binary_dir=$(cat cmake-binary-dir.txt)
  if false; then
    build_dir=$binary_dir/../build-dkt
    rm -fr $build_dir
  fi
  rm -fr $binary_dir
 #rm -fr $binary_dir/{CMakeCache.txt,CMakeFiles,Makefile,build.ninja,rules.ninja}
  bin/cmake-configure.sh
  shift
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh config clean all
