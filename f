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
intmd_dir=/Users/robert/dakota/zzz/intmd
build_dir=/Users/robert/dakota/zzz/build
exe_output_dir=$prefix_dir/bin
lib_output_dir=$prefix_dir/lib
cat /dev/null > $source_dir/build.mk
echo "include dakota-dso/build.mk"          >> $source_dir/build.mk
echo "include dakota-catalog/build.mk"      >> $source_dir/build.mk
echo "include dakota-find-library/build.mk" >> $source_dir/build.mk
dot_files=()
rm -f bin/dakota-catalog bin/dakota-find-library bin/exe-core bin/exe
rm -f lib/libdakota-dso$so_ext lib/libdakota-core$so_ext lib/libdakota$so_ext
rm -fr $source_dir/zzz
for target in ${lib_targets[@]}; do
  current_source_dir=$source_dir/$target
  current_intmd_dir=$intmd_dir/$target
  current_build_dir=$build_dir/$target
  build_mk=$current_intmd_dir/build.mk
  build_dot=$current_intmd_dir/build.dot
  rel_build_mk=${build_mk/$HOME\/dakota\//}
  if [[ ${silent:-0} == 0 ]]; then echo generating $rel_build_mk; fi
  mkdir -p $current_build_dir
  mkdir -p $current_intmd_dir/z
  #dakota-parts --var=current_source_dir=$current_source_dir --var=lib_output_dir=$lib_output_dir
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_output_dir=$lib_output_dir \
              --target-path $lib_output_dir/lib$target$so_ext
  echo "include $build_mk" >> $source_dir/build.mk
  dot_files+=($build_dot)
done
for target in ${exe_targets[@]}; do
  current_source_dir=$source_dir/$target
  current_intmd_dir=$intmd_dir/$target
  current_build_dir=$build_dir/$target
  build_mk=$current_intmd_dir/build.mk
  build_dot=$current_intmd_dir/build.dot
  rel_build_mk=${build_mk/$HOME\/dakota\//}
  if [[ ${silent:-0} == 0 ]]; then echo generating $rel_build_mk; fi
  mkdir -p $current_build_dir
  mkdir -p $current_intmd_dir/z
  #dakota-parts --var=current_source_dir=$current_source_dir --var=lib_output_dir=$lib_output_dir
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_output_dir=$lib_output_dir \
              --target-path $exe_output_dir/$target
  echo "include $build_mk" >> $source_dir/build.mk
  dot_files+=($build_dot)
done
./merge-dots.pl ${dot_files[@]} > $source_dir/build.dot
graphs="${graphs:-0}"
if [[ $graphs -ne 0 ]]; then
  open ${dot_files[@]} $source_dir/build.dot
  exit
fi
threads=$(getconf _NPROCESSORS_ONLN)
threads_per_core=2
jobs=$(( threads / threads_per_core ))
make $@ -j $jobs -f $source_dir/build.mk libdakota-dso
make $@ -j $jobs -f $source_dir/build.mk dakota-catalog
make $@ -j $jobs -f $source_dir/build.mk dakota-find-library
SECONDS=0
make $@ -j $jobs -f $source_dir/build.mk libdakota-core libdakota
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f $source_dir/build.mk exe-core exe
set -o xtrace
bin/exe-core
bin/exe
