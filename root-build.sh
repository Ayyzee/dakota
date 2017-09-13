#!/bin/bash
set -o errexit -o nounset -o pipefail
PATH="~/dakota/bin:$PATH"

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
      verbose=1 build.sh clean
    fi
  fi
  rm -fr $intmd_dir # must delete before $build_dir
  rm -fr $build_dir
  cmake-configure.sh
  if [[ $# -ge 1 ]]; then
    build.sh $@
  fi
else
  build.sh $@
fi

# generator=make;  rm -fr zzz && ./root-build.sh config && ./root-build.sh all && ./root-build.sh test
# generator=ninja; rm -fr zzz && ./root-build.sh config && ./root-build.sh all && ./root-build.sh test
