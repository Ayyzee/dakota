#!/bin/bash
set -o errexit -o nounset -o pipefail
IFS=$'\t\n'

time make -f dakota.mk $@
