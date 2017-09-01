#!/bin/bash
set -o errexit -o nounset -o pipefail -o xtrace
if false; then
  generator=ninja ./root-build.sh config clean
  generator=make  ./root-build.sh config all
else
  generator=make  ./root-build.sh config
  generator=make  ./root-build.sh clean

  generator=ninja ./root-build.sh config
 #generator=ninja ./root-build.sh clean
  generator=ninja ./root-build.sh all
fi

# grep -l build-cmk bin/exe* lib/lib*.* (old build-dir name)
