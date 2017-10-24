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
prefix_dir=$HOME/dakota
source_dir=$HOME/dakota
intmd_dir=$source_dir/z/intmd
build_dir=$source_dir/z/build
bin_dir=$prefix_dir/bin
lib_dir=$prefix_dir/lib
cc_targets=(
  $lib_dir/${lib_prefix}dakota-dso$lib_suffix
  $bin_dir/dakota-catalog$exe_suffix
  $bin_dir/dakota-find-library$exe_suffix
)
dk_lib_targets=(
  $lib_dir/${lib_prefix}dakota-core$lib_suffix
  $lib_dir/${lib_prefix}dakota$lib_suffix
)
dk_exe_targets=(
  $source_dir/tst1/exe$exe_suffix
  $source_dir/tst2/exe$exe_suffix
)
rm -f ${cc_targets[@]} ${dk_lib_targets[@]} ${dk_exe_targets[@]}
dot_files=()
rm -fr $source_dir/z
cat /dev/null > $source_dir/build.mk
echo "include dakota-dso/build.mk"          >> $source_dir/build.mk
echo "include dakota-catalog/build.mk"      >> $source_dir/build.mk
echo "include dakota-find-library/build.mk" >> $source_dir/build.mk
echo "" >> $source_dir/build.mk
dakota-make --var=lib_dir=$lib_dir dakota-core dakota >> $source_dir/build.mk
echo "" >> $source_dir/build.mk
dakota-make --var=lib_dir=$lib_dir tst1 tst2          >> $source_dir/build.mk
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
make $@ -j $jobs -f $source_dir/build.mk ${cc_targets[@]}

make $@ -j $jobs -f $source_dir/build.mk ${dk_lib_targets[@]}
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
make $@ -j $jobs -f $source_dir/build.mk ${dk_exe_targets[@]}
set -o xtrace
$source_dir/tst1/exe$exe_suffix
$source_dir/tst2/exe$exe_suffix
