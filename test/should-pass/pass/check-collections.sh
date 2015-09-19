#!/bin/sh -u

function check()
{
  echo $1;
  pushd $1;
  make check;
  popd;
}

check sets
check counted-sets
check tables
check collection-add-all-first
check collection-forward-iteration
