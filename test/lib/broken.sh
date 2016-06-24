#!/bin/bash
set -o errexit -o nounset -o pipefail
IFS=$'\t\n'

make -f broken.mk
