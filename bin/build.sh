#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ ! -e .binary-dir.txt ]]; then
  binary_dir=build-cmk
  echo $binary_dir > .binary-dir.txt
fi
binary_dir=$(cat .binary-dir.txt)
jobs=$(getconf _NPROCESSORS_ONLN)
jobs=$(( jobs + 2 ))

if [[ -e jobs.txt ]]; then
  jobs=$(cat jobs.txt)
fi
export PATH=$HOME/dakota/bin:$PATH
generator="${generator:-ninja}"
generator_opts=
if   [[ $generator == ninja ]]; then
  generator_opts="-C $binary_dir -j $jobs"
elif [[ $generator == make  ]]; then
  generator_opts="-C $binary_dir -j $jobs --no-print-directory"
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
