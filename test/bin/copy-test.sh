#!/bin/bash

set -o errexit -o nounset -o pipefail

if [ 2 != $# ]; then
  echo "usage: $0 <0|1|2|3> <test-name>"
fi

cp -pr templates/exe-$1 $2
