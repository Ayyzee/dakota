#!/bin/bash

set -o errexit -o nounset -o pipefail

exe_src="auto main() -> int-t { return 0; }" 
echo $exe_src > exe-main.dk
echo $exe_src > exe-util-main.dk
../bin/dakota --output exe exe-main.dk
../bin/dakota --output exe-util exe-util-main.dk /usr/local/lib/libdakota-util.so

set -o verbose

./exe
./exe-util
