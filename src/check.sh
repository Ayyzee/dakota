#!/bin/bash
set -o errexit -o nounset -o pipefail
rootdir=..
source $rootdir/config.sh
src="func main(int-t, const str-t[]) -> int-t { return 0; }" 
echo $src > check.dk
echo $src > check-util.dk
rm -f check
rm -f check-util
set -o verbose
prefix=/usr/local
$prefix/bin/dakota check.dk
$prefix/bin/dakota check-util.dk $prefix/lib/libdakota-util.$so_ext
./check
./check-util
