#!/bin/bash
set -o errexit -o nounset -o pipefail

yaml2cmake.pl dakota-dso/build.yaml          > dakota-dso/build.cmake
yaml2cmake.pl dakota-find-library/build.yaml > dakota-find-library/build.cmake
yaml2cmake.pl dakota-catalog/build.yaml      > dakota-catalog/build.cmake
yaml2cmake.pl dakota-core/build.yaml         > dakota-core/build.cmake
yaml2cmake.pl dakota/build.yaml              > dakota/build.cmake
yaml2cmake.pl exe-core/build.yaml            > exe-core/build.cmake
yaml2cmake.pl exe/build.yaml                 > exe/build.cmake
