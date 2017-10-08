#!/bin/bash
set -o errexit -o nounset -o pipefail
so_ext=dylib
lib_targets=(
  dakota-core
  dakota
)
exe_targets=(
  exe-core
  exe
)
source_dir=/Users/robert/dakota
build_dir=/Users/robert/dakota/zzz/build
cat /dev/null > build.mk
echo "include dakota-dso/build.mk"     >> build.mk
echo "include dakota-catalog/build.mk" >> build.mk
echo "include dakota-find-library/build.mk" >> build.mk
dot_files=()
for target in ${lib_targets[@]}; do
  dakota-make --var=current_source_dir=$source_dir/$target \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --target $source_dir/lib/lib$target.$so_ext
  echo "include $target/build.mk" >> build.mk
  dot_files+=($target/build.dot)
done
for target in ${exe_targets[@]}; do
  dakota-make --var=current_source_dir=$source_dir/$target \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --target $source_dir/bin/$target
  echo "include $target/build.mk" >> build.mk
  dot_files+=($target/build.dot)
done
./merge-dots.pl ${dot_files[@]} > build.dot
graphs="${graphs:-0}"
if [[ $graphs -ne 0 ]]; then
  open ${dot_files[@]} build.dot
  exit
fi
rm -f bin/dakota-catalog bin/dakota-find-library
rm -f lib/libdakota-dso.$so_ext lib/libdakota-core.$so_ext lib/libdakota.$so_ext
rm -fr zzz
make $@ -f build.mk libdakota-dso
make $@ -f build.mk dakota-catalog
make $@ -f build.mk dakota-find-library
#jobs=$(getconf _NPROCESSORS_ONLN)
#jobs=$(( jobs + 2 ))
jobs=4
SECONDS=0
make $@ -j $jobs -f build.mk libdakota
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f build.mk exe-core exe
set -o xtrace
bin/exe-core
bin/exe
