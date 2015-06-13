#!/bin/bash

set -o nounset -o errexit -o pipefail

objdir=obj
so_ext=dylib # darwin

function lslt
{
  return_value=0
  for file in "$@"; do
    #size=`stat -c%s $file 2>/dev/null` # linux
    #if [[ $? -eq 0 ]]; then
    #  echo $size $file
    #  printf "% 9i %s\n" $size $file
    #else
    #  return_value=1
    #fi

    eval $(stat -s $file) # darwin
    if [[ $? -eq 0 ]]; then
      printf "% 9i %s\n" $st_size $file
    else
      return_value=1
    fi
  done
  return $return_value
}
lslt $objdir/dakota/lib/libdakota.dylib.ctlg.rep\
     $objdir/dakota/lib/libdakota.rep
echo
lslt $objdir/dakota/lib/libdakota-util.dylib.ctlg.rep\
     $objdir/dakota/lib/libdakota-util.rep
