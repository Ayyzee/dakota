#!/bin/bash
set -o errexit -o nounset -o pipefail
for tgt in dakota-core dakota; do
  dakota-make.pl --var=build_dir=/Users/robert/dakota/zzz/build/$tgt --var=source_dir=/Users/robert/dakota/$tgt --target /Users/robert/dakota/lib/lib$tgt.dylib #--parts /Users/robert/dakota/$tgt/parts.txt
done
rm -rf zzz
SECONDS=0
make $@ -j 10 -f build.mk
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
