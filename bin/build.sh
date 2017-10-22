#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ ! -e .build-dir.txt ]]; then
  build_dir=z/build
  echo $build_dir > .build-dir.txt
fi
build_dir=$(cat .build-dir.txt)
jobs="${jobs:-0}"
if [[ $jobs -eq 0 ]]; then
  jobs=$(getconf _NPROCESSORS_ONLN)
  jobs=$(( jobs + 2 ))
fi
prefix_dir=$HOME/dakota
export PATH=$prefix_dir/bin:$PATH
generator="${generator:-ninja}"
generator_opts=
if   [[ $generator == ninja ]]; then
  generator_opts="-C $build_dir -j $jobs"
elif [[ $generator == make  ]]; then
  generator_opts="-C $build_dir -j $jobs --no-print-directory"
fi
verbose="${verbose:-0}"
if [[ $verbose -ne 0 ]]; then
  export DAKOTA_VERBOSE=1
  #export CMAKE_VERBOSE_MAKEFILE=ON
  if   [[ $generator == ninja ]]; then
    generator_opts="$generator_opts -v"
  elif [[ $generator == make  ]]; then
    generator_opts="$generator_opts VERBOSE=1"
  fi
fi
SECONDS=0
$generator $generator_opts $@
duration=$SECONDS
echo "duration: $(($duration / 60))m$(($duration % 60))s"
