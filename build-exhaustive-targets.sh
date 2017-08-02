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

echo 1 > jobs.txt

bin/cmake-configure.sh
bin/build.sh clean
if [[ $# -ge 1 && $1 != clean ]]; then
    echo bin/build.sh $@
fi
