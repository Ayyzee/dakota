#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

rm -fr {dakota-dso,dakota-catalog,dakota-core,dakota}/build-{dkt,cmk}
rm -fr build-dkt build-cmk

echo 1 > jobs.txt

bin/cmake-configure.sh
bin/build.sh clean
bin/build.sh all
