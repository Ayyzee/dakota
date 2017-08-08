#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

build() {
  SECONDS=0; bin/build.sh $@; duration=$SECONDS; echo "duration: $(($duration / 60))m$(($duration % 60))s"
}
if [[ $# -ge 1 && $1 == config ]]; then
  binary_dir=$(cat cmake-binary-dir.txt)
  build_dir=$binary_dir/../build-dkt
  # must delete build_dir before binary_dir
  rm -fr $build_dir # ninja ignore ADDITIONAL_MAKE_CLEAN_FILES
  rm -fr $binary_dir
  bin/cmake-configure.sh
  shift
  if [[ $# -ge 1 ]]; then
    build $@
  fi
else
  build $@
fi

# generator=make generator_id="Unix Makefiles" ./root-build.sh ...
