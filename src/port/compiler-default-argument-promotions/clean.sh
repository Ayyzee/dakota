#!/bin/bash

set -o errexit -o nounset -o pipefail

rm -f  type-index
rm -fr type-index.dSYM

rm -f exe-main.dk # yes, this is not a mistake
