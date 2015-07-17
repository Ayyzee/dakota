#!/bin/bash

set -o nounset -o errexit -o pipefail

objdir=obj
so_ext=dylib # linux: so_ext=so, darwin: so_ext=dylib
mkdir -p check-history
output=check-history/$(basename $0)-$$.txt
rm -f $output
touch $output

{
./bin/lslt ../lib/libdakota.$so_ext
./bin/lslt ../lib/libdakota-util.$so_ext
echo
./bin/lslt $objdir/dakota/lib/libdakota.$so_ext.rep\
           $objdir/dakota/lib/libdakota.rep
echo
./bin/lslt $objdir/dakota/lib/libdakota-util.$so_ext.rep\
           $objdir/dakota/lib/libdakota-util.rep
echo
bin/build-file-size-summary.pl
} > $output

cat $output
