#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  rm -f */build.cmake
}
trap finish EXIT
targets=(
  lib/libdakota-dso.dylib  # 1
  bin/dakota-catalog       # 2
  bin/dakota-find-library  # 2
  lib/libdakota-core.dylib # 3
  lib/libdakota.dylib      # 4
  bin/exe-core             # 5
  bin/exe                  # 5
)
#rm -f ${targets[@]}
set -o xtrace
rm -fr zzz
yaml2cmake.sh
export generator=ninja
./root-build.sh config
./root-build.sh dakota-dso dakota-catalog dakota-find-library
./root-build.sh dakota-core dakota
./root-build.sh exe-core exe
./root-build.sh test
