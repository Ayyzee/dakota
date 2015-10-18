#!/bin/bash

set -o errexit -o nounset -o pipefail

line=$(grep -n 'dk_hash_switch' obj/exe-main.cc /dev/null | grep int1)
if [[ 0 == $? ]]; then
    echo $line: switch expression should not have been rewritten.
fi
