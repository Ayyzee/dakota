#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  rm -f */build.cmake
}
trap finish EXIT
lib_prefix=lib
lib_suffix='.dylib'
exe_suffix=
lib_targets=(
  dakota-core
  dakota
)
exe_targets=(
  tst1
  tst2
)
prefix_dir=/Users/robert/dakota
source_dir=/Users/robert/dakota
intmd_dir=/Users/robert/dakota/zzz/intmd
build_dir=/Users/robert/dakota/zzz/build
bin_dir=$prefix_dir/bin
lib_dir=$prefix_dir/lib
cat /dev/null > $source_dir/build.mk
echo "include dakota-dso/build.mk"          >> $source_dir/build.mk
echo "include dakota-catalog/build.mk"      >> $source_dir/build.mk
echo "include dakota-find-library/build.mk" >> $source_dir/build.mk
dot_files=()
rm -f bin/dakota-catalog$exe_suffix bin/dakota-find-library$exe_suffix
rm -f lib/${lib_prefix}dakota-dso$lib_suffix lib/${lib_prefix}dakota-core$lib_suffix lib/${lib_prefix}dakota$lib_suffix
rm -f tst1/exe$exe_suffix tst2/exe$exe_suffix
rm -fr $source_dir/zzz
for target in ${lib_targets[@]}; do
  current_source_dir=$source_dir/$target
  current_intmd_dir=$intmd_dir/$target
  current_build_dir=$build_dir/$target
  build_mk=$current_intmd_dir/build.mk
  build_dot=$current_intmd_dir/build.dot
  target_path=$lib_dir/$lib_prefix$target$lib_suffix
  rel_build_mk=${build_mk/$HOME\/dakota\//}
  if [[ ${silent:-0} == 0 ]]; then echo "# generating $rel_build_mk"; fi
  mkdir -p $current_build_dir
  mkdir -p $current_intmd_dir/z
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_dir=$lib_dir \
              --target-path $target_path
  echo "include $build_mk" >> $source_dir/build.mk
  dot_files+=($build_dot)
done
for target in ${exe_targets[@]}; do
  current_source_dir=$source_dir/$target
  current_intmd_dir=$intmd_dir/$target
  current_build_dir=$build_dir/$target
  build_mk=$current_intmd_dir/build.mk
  build_dot=$current_intmd_dir/build.dot
  target_path=$source_dir/$target/exe$exe_suffix
  rel_build_mk=${build_mk/$HOME\/dakota\//}
  if [[ ${silent:-0} == 0 ]]; then echo "# generating $rel_build_mk"; fi
  mkdir -p $current_build_dir
  mkdir -p $current_intmd_dir/z
  dakota-make --var=current_source_dir=$current_source_dir \
              --var=source_dir=$source_dir \
              --var=build_dir=$build_dir \
              --var=lib_dir=$lib_dir \
              --target-path $target_path
  echo "include $build_mk" >> $source_dir/build.mk
  dot_files+=($build_dot)
done
merge-dots.pl ${dot_files[@]} > $source_dir/build.dot
graphs="${graphs:-0}"
if [[ $graphs -ne 0 ]]; then
  open ${dot_files[@]} $source_dir/build.dot
  exit
fi
threads=$(getconf _NPROCESSORS_ONLN)
threads_per_core=2
jobs=$(( threads / threads_per_core ))
SECONDS=0
make $@ -j $jobs -f $source_dir/build.mk $lib_dir/${lib_prefix}dakota-dso$lib_suffix $bin_dir/dakota-catalog$exe_suffix $bin_dir/dakota-find-library$exe_suffix
make $@ -j $jobs -f $source_dir/build.mk $lib_dir/${lib_prefix}dakota-core$lib_suffix $lib_dir/${lib_prefix}dakota$lib_suffix
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f $source_dir/build.mk $source_dir/tst1/exe$exe_suffix $source_dir/tst2/exe$exe_suffix
set -o xtrace
$source_dir/tst1/exe$exe_suffix
$source_dir/tst2/exe$exe_suffix
