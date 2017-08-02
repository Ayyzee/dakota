#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

#rm -fr $(cat cmake-binary-dir.txt)
bin/cmake-configure.sh
bin/build.sh $@
