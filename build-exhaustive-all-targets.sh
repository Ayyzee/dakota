#!/bin/bash
set -o errexit -o nounset -o pipefail
export PATH=$HOME/dakota/bin:$PATH
export DAKOTA_VERBOSE=1
export CMAKE_VERBOSE_MAKEFILE=ON

bin/dakota-uninstall.sh /usr/local
bin/build-uninstall.sh

rm -fr {dakota-dso,dakota-find-library,dakota-catalog,dakota-core,dakota}/build-{dkt,cmk}
rm -fr build-dkt build-cmk

bin/cmake-configure.sh

# bin/build.sh clean all install
bin/build.sh clean
bin/build.sh all
bin/build.sh install
