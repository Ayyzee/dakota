#!/bin/bash
set -o errexit -o nounset -o pipefail

yaml2cmake.pl dakota-dso/build-vars.yaml          > dakota-dso/build-vars.cmake
yaml2cmake.pl dakota-find-library/build-vars.yaml > dakota-find-library/build-vars.cmake
yaml2cmake.pl dakota-catalog/build-vars.yaml      > dakota-catalog/build-vars.cmake
yaml2cmake.pl dakota-core/build-vars.yaml         > dakota-core/build-vars.cmake
yaml2cmake.pl dakota/build-vars.yaml              > dakota/build-vars.cmake
yaml2cmake.pl exe-core/build-vars.yaml            > exe-core/build-vars.cmake
yaml2cmake.pl exe/build-vars.yaml                 > exe/build-vars.cmake
