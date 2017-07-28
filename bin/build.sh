#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ $# == 0 ]]; then
  args=all
else
  args=$@
fi
count=0
index_of_all=-1
count-and-index-of-all() {
  for arg in $args; do
    if [[ $arg == 'all' ]]; then
      index_of_all=$count
    fi
    count=$((count + 1))
  done
}
ee() {
  echo cwd=$PWD
  echo $1
  eval $1
}
if [[ -e ../cmake-binary-dir.txt ]]; then
  binary_dir=$(cat ../cmake-binary-dir.txt)
else
  binary_dir=build-cmk
fi
jobs=$(getconf _NPROCESSORS_ONLN)
targets=$(cmake --build $binary_dir --target help)
targets=$(echo $targets)
init_re="... init ..."
if [[ $targets =~ $init_re ]]; then
  count-and-index-of-all $args # sets 'count' and 'index_of_all'
  #echo count = $count, index_of_all = $index_of_all
  if [[ $index_of_all != -1 ]]; then
    for arg in $args; do # sub-optimal
      if [[ "$arg" == "all" ]]; then
        ee "make --directory $binary_dir init"
        ee "make --directory $binary_dir --jobs $jobs all"
      else
        ee "make --directory $binary_dir $arg"
      fi
    done
  else
    ee "make --directory $binary_dir $args"
  fi
else
  ee "make --directory $binary_dir $args"
fi

# This could be done better. The for loop labeled sub-optimal should be
# replaced with three four calls
# 1) the group of targets before 'all'
# 2) the target 'init'
# 3) the target 'all'
# 4) and the group of targets after 'all'
