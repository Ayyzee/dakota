#!/bin/bash
set -o errexit -o nounset -o pipefail
dakota-make.sh
rm -rf zzz
SECONDS=0
skip_submake=1 make -j 10 -f build.mk
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
