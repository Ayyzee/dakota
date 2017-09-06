#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  shift
  if [[ ! -e .binary-dir.txt ]]; then
    binary_dir=build/cmk
    echo $binary_dir > .binary-dir.txt
  fi
  binary_dir=$(cat .binary-dir.txt)
  intmdt_dir=$binary_dir/../dkt
  if [[ ${clean:-0} -ne 0 ]]; then
    #rm -f bin/dakota-catalog bin/exe* lib/libdakota*
    if [[ -e $binary_dir/CMakeFiles/Makefile2 || -e $binary_dir/build.ninja ]]; then
      verbose=1 bin/build.sh clean
    fi
  fi
  rm -fr $intmdt_dir # must delete before $binary_dir
  rm -fr $binary_dir
  bin/cmake-configure.sh
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh config all test
