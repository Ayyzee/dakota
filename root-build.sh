#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  binary_dir=$(cat cmake-binary-dir.txt)
  # must delete build_dir before binary_dir
  if [[ ${force:-0} -ne 0 ]]; then
    build_dir=$binary_dir/../build-dkt
    rm -fr $build_dir # ninja ignore ADDITIONAL_MAKE_CLEAN_FILES
  fi
  rm -fr $binary_dir
  bin/cmake-configure.sh
  shift
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh ...
