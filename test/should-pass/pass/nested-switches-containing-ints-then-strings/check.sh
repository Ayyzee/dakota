#!/bin/bash

set -o errexit -o nounset -o pipefail

line=$(grep -n 'dkt_hash_switch(int1)' obj/exe-main.cc /dev/null)
if [[ 0 == $? ]]; then
    echo $line: switch expression should not have been rewritten.
fi
