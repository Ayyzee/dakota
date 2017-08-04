#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

if [[ $# -ge 1 && $1 == config ]]; then
  rm -fr $(cat cmake-binary-dir.txt)
  bin/cmake-configure.sh
  rm -f */parts.yaml # hackhack
  shift
  if [[ $# -ge 1 ]]; then
    bin/build.sh $@
  fi
else
  bin/build.sh $@
fi
