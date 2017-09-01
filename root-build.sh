#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  shift
  if [[ ! -e .binary-dir.txt ]]; then
    binary_dir=build-cmk
    echo $binary_dir > .binary-dir.txt
  fi
  binary_dir=$(cat .binary-dir.txt)
  build_dir=$binary_dir/../build-dkt
  #if [[ -e $binary_dir/Makefile || -e $binary_dir/build.ninja ]]; then
  #  bin/build.sh clean
  #fi
  #rm -f bin/exe* bin/dakota-catalog lib/libdakota*
  rm -fr $build_dir # must delete before $binary_dir
  rm -fr $binary_dir
  bin/cmake-configure.sh
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh config clean all
