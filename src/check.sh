#!/bin/bash

set -o nounset -o errexit -o pipefail

objdir=obj
so_ext=dylib # linux: so_ext=so, darwin: so_ext=dylib
mkdir -p check-history
rm -f check-history/$$.txt
touch check-history/$$.txt

{
./bin/lslt $objdir/dakota/lib/libdakota.$so_ext.rep\
           $objdir/dakota/lib/libdakota.rep
echo
./bin/lslt $objdir/dakota/lib/libdakota-util.$so_ext.rep\
           $objdir/dakota/lib/libdakota-util.rep
echo
bin/build-file-size-summary.pl
} > check-history/$$.txt

cat check-history/$$.txt
