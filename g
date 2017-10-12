#!/bin/bash
set -o errexit -o nounset -o pipefail
targets=(
  lib/libdakota-dso.dylib  # 1
  lib/libdakota-core.dylib # 3
  lib/libdakota.dylib      # 4
  bin/dakota-catalog       # 2
  bin/exe-core             # 5
  bin/exe                  # 5
)
#rm -f ${targets[@]}
set -o xtrace
rm -rf zzz
rm -f {dakota-core,dakota}/parts.txt
export generator=ninja
./root-build.sh config
./root-build.sh dakota-dso dakota-catalog
./root-build.sh dakota-core dakota
./root-build.sh exe-core exe
./root-build.sh test
