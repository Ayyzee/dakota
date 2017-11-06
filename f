#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  echo -n ""
}
trap finish EXIT
lib_files() {
  while [[ $# -gt 0 ]]; do
    target=$1
    echo $lib_dir/$lib_prefix$target$lib_suffix
    shift
  done
}
exe_files() {
  while [[ $# -gt 0 ]]; do
    target=$1
    echo $bin_dir/$target$exe_suffix
    shift
  done
}
tst_exe_files() {
  while [[ $# -gt 0 ]]; do
    dir=$1
    cwd=$(pwd)
    echo $cwd/$dir/exe$exe_suffix
    shift
  done
}
lib_prefix=lib
lib_suffix='.dylib'
exe_suffix=
ext_lib_targets=(
  dakota-dso
)
ext_exe_targets=(
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
lib_target_yamls=(
  $source_dir/dakota-core/build.yaml
  $source_dir/dakota/build.yaml
)
exe_target_yamls=(
  $source_dir/tst1/build.yaml
  $source_dir/tst2/build.yaml
)
rel_build_dir=z/build
build_dir=$source_dir/$rel_build_dir
intmd_dir=$build_dir/../intmd
bin_dir=$prefix_dir/bin
lib_dir=$prefix_dir/lib
ext_lib_files=($(lib_files     ${ext_lib_targets[@]}))
ext_exe_files=($(exe_files     ${ext_exe_targets[@]}))
lib_files=(    $(lib_files     ${lib_targets[@]}))
exe_files=(    $(tst_exe_files ${exe_targets[@]}))
rm -f ${ext_lib_files[@]} ${ext_exe_files[@]} ${lib_files[@]} ${exe_files[@]}
dot_files=()
rm -fr $(dirname $build_dir)
mkdir -p $intmd_dir
build=build
cat /dev/null > $intmd_dir/$build.mk
for ext_target in ${ext_lib_targets[@]} ${ext_exe_targets[@]}; do
  echo "include $prefix_dir/$ext_target/build.mk" >> $intmd_dir/$build.mk
done
lib_build_files=($(dakota-make --var=lib_dir=$lib_dir ${lib_target_yamls[@]}))
echo "" >> $intmd_dir/$build.mk
for build_file in ${lib_build_files[@]}; do echo "include $build_file" >> $intmd_dir/$build.mk; done
exe_build_files=($(dakota-make --var=lib_dir=$lib_dir ${exe_target_yamls[@]}))
echo "" >> $intmd_dir/$build.mk
for build_file in ${exe_build_files[@]}; do echo "include $build_file" >> $intmd_dir/$build.mk; done
dot_files=($(echo $intmd_dir/{dakota-core,dakota,tst1,tst2}/build.dot))
merge-dots.pl ${dot_files[@]} > $intmd_dir/build.dot
graphs="${graphs:-0}"
if [[ $graphs -ne 0 ]]; then
  open ${dot_files[@]} $intmd_dir/build.dot
  exit
fi
threads=$(getconf _NPROCESSORS_ONLN)
threads_per_core=2
jobs=$(( threads / threads_per_core ))
SECONDS=0
make $@ -j $jobs -f $intmd_dir/$build.mk ${ext_lib_files[@]} ${ext_exe_files[@]}

make $@ -j $jobs -f $intmd_dir/$build.mk ${lib_files[@]}
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f $intmd_dir/$build.mk ${exe_files[@]}
for exe_file in ${exe_files[@]}; do
  echo \# $exe_file
  $exe_file
done
