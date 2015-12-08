#!/bin/bash

set -o errexit -o nounset -o pipefail

src="func main(int-t, const str-t[]) -> int-t { return 0; }" 
echo $src > check.dk
echo $src > check-util.dk
../bin/dakota --output check check.dk
../bin/dakota --output check-util check-util.dk /usr/local/lib/libdakota-util.so

set -o verbose

./check
./check-util
