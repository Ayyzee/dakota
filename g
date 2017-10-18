#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  rm -f */build.cmake
}
trap finish EXIT
lib_prefix=lib
lib_suffix=.dylib
exe_suffix=
targets=(
  lib/$lib_prefix/dakota-dso$lib_suffix  # 1
  bin/dakota-catalog$exe_suffix          # 2
  bin/dakota-find-library$exe_suffix     # 2
  lib/$lib_prefix/dakota-core$lib_suffix # 3
  lib/$lib_prefix/dakota$lib_suffix      # 4
  tst1/exe$exe_suffix                    # 5
  tst2/exe$exe_suffix                    # 5
)
#rm -f ${targets[@]}
set -o xtrace
rm -fr zzz
yaml2cmake.sh
export generator=ninja
./root-build.sh config
./root-build.sh dakota-dso dakota-catalog dakota-find-library
./root-build.sh dakota-core dakota
./root-build.sh tst1 tst2
./root-build.sh test
