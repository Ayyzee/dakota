#!/bin/bash

set -o errexit -o nounset -o pipefail

paths-from-pattern()
{
  pattern="$1"
  paths=$(echo $pattern)
  if [[ "$pattern" == "$paths" ]]; then
    paths=""
  fi
  echo $paths
}
