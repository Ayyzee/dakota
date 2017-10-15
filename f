#!/bin/bash
set -o errexit -o nounset -o pipefail
so_ext='.dylib'
lib_targets=(
  dakota-core
  dakota
)
exe_targets=(
  exe-core
  exe
)
prefix_dir=/Users/robert/dakota
source_dir=/Users/robert/dakota
build_dir=/Users/robert/dakota/zzz/build
exe_output_dir=$prefix_dir/bin
lib_output_dir=$prefix_dir/lib
cat /dev/null > build.mk
echo "include dakota-dso/build.mk"     >> build.mk
echo "include dakota-catalog/build.mk" >> build.mk
echo "include dakota-find-library/build.mk" >> build.mk
dot_files=()
rm -f */parts.txt
rm -f {dakota-core,dakota,exe-core,exe}/build.mk
for target in ${lib_targets[@]}; do
  current_source_dir=$source_dir/$target
  #dakota-parts --var=current_source_dir=$current_source_dir --var=lib_output_dir=$lib_output_dir
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_output_dir=$lib_output_dir \
              --target $lib_output_dir/lib$target$so_ext
  echo "include $target/build.mk" >> build.mk
  dot_files+=($target/build.dot)
done
for target in ${exe_targets[@]}; do
  current_source_dir=$source_dir/$target
  #dakota-parts --var=current_source_dir=$current_source_dir --var=lib_output_dir=$lib_output_dir
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_output_dir=$lib_output_dir \
              --target $exe_output_dir/$target
  echo "include $target/build.mk" >> build.mk
  dot_files+=($target/build.dot)
done
./merge-dots.pl ${dot_files[@]} > build.dot
graphs="${graphs:-0}"
if [[ $graphs -ne 0 ]]; then
  open ${dot_files[@]} build.dot
  exit
fi
rm -f bin/dakota-catalog bin/dakota-find-library bin/exe-core bin/exe
rm -f lib/libdakota-dso$so_ext lib/libdakota-core$so_ext lib/libdakota$so_ext
rm -fr zzz
make $@ -f build.mk libdakota-dso
make $@ -f build.mk dakota-catalog
make $@ -f build.mk dakota-find-library
threads=$(getconf _NPROCESSORS_ONLN)
threads_per_core=2
jobs=$(( threads / threads_per_core ))
SECONDS=0
make $@ -j $jobs -f build.mk libdakota
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f build.mk exe-core exe
set -o xtrace
bin/exe-core
bin/exe
