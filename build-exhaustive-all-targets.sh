#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  rm -f jobs.txt
}
trap finish EXIT
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

rm -fr {dakota-dso,dakota-catalog,dakota-core,dakota}/build-{dkt,cmk}
rm -fr build-dkt build-cmk
#rm -fr bin/dakota-catalog
#rm -fr lib/lib{dakota-dso,dakota-core,dakota}.dylib

echo 1 > jobs.txt

bin/cmake-configure.sh
bin/build.sh clean
bin/build.sh $@
