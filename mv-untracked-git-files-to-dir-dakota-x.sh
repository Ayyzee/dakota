#!/bin/bash

set -o nounset -o errexit -o pipefail

# this script moves git untracked files from tracked directories
# only one level deep (assuming an untracked directory of untracked files
# is important and should be added/commited or hand deleted)

if [[ "/Users/robert/github/dakota" != $PWD ]]; then
    exit 1;
fi

mkdir -p ../dakota-x
git stash
paths=$(git status --short | colrm 1 3)

for path in $paths; do
  if [[ $path =~ /$ ]]; then
    echo mkdir -p ../dakota-x
  else
    dir=$(dirname $path)
    file=$(basename $path)
    if [[ $file =~ ^\. ]]; then
      echo "omitting " $path
    else
      mkdir -p ../dakota-x/$dir
      mv $path ../dakota-x/$dir
    fi
  fi
done
