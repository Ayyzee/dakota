#!/bin/bash
set -o nounset -o pipefail -o xtrace -o errexit
rm -f libtest.so
export OBJDIR=/tmp/current-lib
rm -rf $OBJDIR
mkdir -p $OBJDIR
../bin/dakota --compile --project libtest.project --output $OBJDIR/test1.cc.o test1.dk
../bin/dakota --compile --project libtest.project --output $OBJDIR/test2.cc.o test2.dk

../bin/dakota --shared  --project libtest.project --output libtest.so $OBJDIR/test1.cc.o $OBJDIR/test2.cc.o
../bin/dakota-catalog ./libtest.so
