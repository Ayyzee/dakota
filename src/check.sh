#!/bin/bash
set -o errexit -o nounset -o pipefail
src="func main(int-t, const str-t[]) -> int-t { return 0; }" 
echo $src > check.dk
echo $src > check-util.dk
set -o verbose
prefix=/usr/local
../bin/dakota check.dk
../bin/dakota check-util.dk $prefix/lib/libdakota-util.so
./check
./check-util
