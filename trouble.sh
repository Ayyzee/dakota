#!/bin/bash
set -o errexit -o nounset -o pipefail -o xtrace
if false; then
  generator=ninja ./root-build.sh config clean
  generator=make  ./root-build.sh config clean all
else
  generator=make  ./root-build.sh config clean
  generator=ninja ./root-build.sh config clean all
fi
