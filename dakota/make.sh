#!/bin/bash
set -o errexit -o nounset -o pipefail

time make -f dakota.mk $@
