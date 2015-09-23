#!/bin/bash

set -o nounset -o errexit -o pipefail

if [ 2 != $# ]; then
  echo "usage: $0 <0|1|2|3> <test-name>"
fi

cp -r TEMPLATE-exe-$1 $2
