#!/bin/bash

set -o nounset -o errexit -o pipefail

for (( n=0; n<$1; n++ )); do
    echo $n
done
