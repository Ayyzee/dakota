#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  shift
  if [[ ! -e .build-dir.txt ]]; then
    build_dir=zzz/build
    echo $build_dir > .build-dir.txt
  fi
  build_dir=$(cat .build-dir.txt)
  intmd_dir=$build_dir/../dkt
  if [[ ${clean:-0} -ne 0 ]]; then
    #rm -f bin/dakota-catalog bin/exe* lib/libdakota*
    if [[ -e $build_dir/CMakeFiles/Makefile2 || -e $build_dir/build.ninja ]]; then
      verbose=1 bin/build.sh clean
    fi
  fi
  rm -fr $intmd_dir # must delete before $build_dir
  rm -fr $build_dir
  bin/cmake-configure.sh
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh config all test
