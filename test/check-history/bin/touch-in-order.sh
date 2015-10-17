#!/bin/bash

set -o errexit -o nounset -o pipefail

skip=0
for path in $(cat check-history/should-pass/pass.txt); do
    if [[ 0 != $skip ]]; then
        skip=0
    else
        touch $path
        sleep 2
        skip=1
    fi
done
