#!/bin/bash
set -o errexit -o nounset -o pipefail

mkdir -p z/build/{dakota-dso,dakota-find-library,dakota-catalog,dakota-core,dakota,tst1,tst2}

yaml2cmake.pl dakota-dso/build.yaml          > z/build/dakota-dso/build.cmake
yaml2cmake.pl dakota-find-library/build.yaml > z/build/dakota-find-library/build.cmake
yaml2cmake.pl dakota-catalog/build.yaml      > z/build/dakota-catalog/build.cmake
yaml2cmake.pl dakota-core/build.yaml         > z/build/dakota-core/build.cmake
yaml2cmake.pl dakota/build.yaml              > z/build/dakota/build.cmake
yaml2cmake.pl tst1/build.yaml                > z/build/tst1/build.cmake
yaml2cmake.pl tst2/build.yaml                > z/build/tst2/build.cmake
