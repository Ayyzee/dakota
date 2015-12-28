#!/bin/bash
set -o errexit -o nounset -o pipefail
rootdir=..
#source $rootdir/common.sh
source $rootdir/config.sh
src="func main(int-t, const str-t[]) -> int-t { return 0; }" 
echo $src > installcheck.dk
echo $src > installcheck-util.dk
rm -f installcheck
rm -f installcheck-util
set -o verbose
DEST=
prefix=/usr/local
$DEST$prefix/bin/dakota installcheck.dk
$DEST$prefix/bin/dakota installcheck-util.dk $DEST$prefix/lib/libdakota-util.$so_ext
./installcheck
./installcheck-util
