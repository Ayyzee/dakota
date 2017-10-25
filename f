#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  rm -f */build.cmake
  rm -f {dakota-core,dakota,tst1,tst2}/build.mk
}
trap finish EXIT
lib_prefix=lib
lib_suffix='.dylib'
exe_suffix=
ext_targets=(
  dakota-dso
  dakota-catalog
  dakota-find-library
)
lib_targets=(
  dakota-core
  dakota
)
exe_targets=(
  tst1
  tst2
)
prefix_dir=$HOME/dakota
source_dir=$HOME/dakota
intmd_dir=$source_dir/z/intmd
build_dir=$source_dir/z/build
bin_dir=$prefix_dir/bin
lib_dir=$prefix_dir/lib
ext_files=(
  $lib_dir/${lib_prefix}dakota-dso$lib_suffix
  $bin_dir/dakota-catalog$exe_suffix
  $bin_dir/dakota-find-library$exe_suffix
)
lib_files=(
  $lib_dir/${lib_prefix}dakota-core$lib_suffix
  $lib_dir/${lib_prefix}dakota$lib_suffix
)
exe_files=(
  $source_dir/tst1/exe$exe_suffix
  $source_dir/tst2/exe$exe_suffix
)
rm -f ${ext_files[@]} ${lib_files[@]} ${exe_files[@]}
dot_files=()
rm -fr $source_dir/z
build=build.mk
cat /dev/null > $build
for ext_target in ${ext_targets[@]}; do
  echo "include $ext_target/build.mk" >> $build
done
lib_build_files=($(dakota-make --var=lib_dir=$lib_dir --output $build ${lib_targets[@]}))
echo "" >> $build
for build_file in ${lib_build_files[@]}; do echo "include $build_file" >> $build; done
exe_build_files=($(dakota-make --var=lib_dir=$lib_dir --output $build ${exe_targets[@]}))
echo "" >> $build
for build_file in ${exe_build_files[@]}; do echo "include $build_file" >> $build; done
dot_files=($(echo $intmd_dir/{dakota-core,dakota,tst1,tst2}/build.dot))
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
make $@ -j $jobs -f $build ${ext_files[@]}

make $@ -j $jobs -f $build ${lib_files[@]}
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f $build ${exe_files[@]}
for exe_target in ${exe_files[@]}; do
  echo \# $exe_target
  $exe_target
done
