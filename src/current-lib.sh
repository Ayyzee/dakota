#!/bin/bash
set -o nounset -o pipefail -o xtrace -o errexit
../bin/dakota --clean --project libtest.project
cat libtest.io
rm -f libtest.io
find obj/libtest -type f
rm -rf obj/libtest
../bin/dakota --compile --project libtest.project
#cat libtest.io
../bin/dakota --shared  --project libtest.project
#cat libtest.io
../bin/dakota-catalog ./libtest.so
#exit

echo ===

../bin/dakota --clean --project libtest.project
builddir=obj/libtest
rm -rf $builddir
mkdir -p $builddir
../bin/dakota --compile --project libtest.project --output $builddir/test1.cc.o test1.dk
../bin/dakota --compile --project libtest.project --output $builddir/test2.cc.o test2.dk

../bin/dakota --shared  --project libtest.project --output libtest.so $builddir/test1.cc.o $builddir/test2.cc.o
../bin/dakota-catalog ./libtest.so

