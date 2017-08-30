#!/bin/bash
set -o errexit -o nounset -o pipefail

if [[ $# -ge 1 && $1 == config ]]; then
  binary_dir=$(cat cmake-binary-dir.txt)
  rm -fr $binary_dir
  bin/cmake-configure.sh
  shift
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi

# generator=make ./root-build.sh config clean all
