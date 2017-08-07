#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

build() {
  SECONDS=0; bin/build.sh $@; duration=$SECONDS; echo "duration: $(($duration / 60))m$(($duration % 60))s"
}
if [[ $# -ge 1 && $1 == config ]]; then
  rm -fr $(cat cmake-binary-dir.txt)
  bin/cmake-configure.sh
  shift
  if [[ $# -ge 1 ]]; then
    build $@
  fi
else
  build $@
fi
