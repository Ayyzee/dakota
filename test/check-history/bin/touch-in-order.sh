#!/bin/bash

set -o errexit -o nounset -o pipefail

for path in $(cat check-history/should-pass/pass.txt); do
    touch $path
    sleep 2
done
