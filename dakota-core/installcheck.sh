#!/bin/bash
set -o errexit -o nounset -o pipefail
finish() {
  find $OBJDIR -type f | sort
}
trap finish EXIT
rootdir=..
source $rootdir/common.sh
source $rootdir/config.sh
export OBJDIR=/tmp/installcheck
rm -fr $OBJDIR

# compile <>.o
rm -f installcheck-o.o installcheck-util-o.o
cat /dev/null > installcheck-o.dk
cat /dev/null > installcheck-util-o.dk
set -o verbose
$DESTDIR$INSTALL_PREFIX/bin/dakota --compile installcheck-o.dk
$DESTDIR$INSTALL_PREFIX/bin/dakota --compile installcheck-util-o.dk $DESTDIR$INSTALL_PREFIX/lib/libdakota.$so_ext
set +o verbose
rm -f installcheck-o.dk installcheck-util-o.dk

# compile/link <>.so
rm -f installcheck-so.so installcheck-util-so.so
cat /dev/null > installcheck-so.dk
cat /dev/null > installcheck-util-so.dk
rm -f installcheck-so.so installcheck-util-so.so
set -o verbose
$DESTDIR$INSTALL_PREFIX/bin/dakota --shared installcheck-so.dk
$DESTDIR$INSTALL_PREFIX/bin/dakota --shared installcheck-util-so.dk $DESTDIR$INSTALL_PREFIX/lib/libdakota.$so_ext
dakota-catalog installcheck-so.so
dakota-catalog installcheck-util-so.so
set +o verbose
rm -f installcheck-so.dk installcheck-util-so.dk

# compile/link <> executable
rm -f installcheck installcheck-util
src="func main(int-t, const str-t[]) -> int-t { EXIT(0); }" 
echo $src > installcheck.dk
echo $src > installcheck-util.dk
rm -f installcheck installcheck-util
set -o verbose
$DESTDIR$INSTALL_PREFIX/bin/dakota installcheck.dk
$DESTDIR$INSTALL_PREFIX/bin/dakota installcheck-util.dk $DESTDIR$INSTALL_PREFIX/lib/libdakota.$so_ext
./installcheck
./installcheck-util
set +o verbose
rm -f installcheck.dk installcheck-util.dk
