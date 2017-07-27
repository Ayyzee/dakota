#!/bin/bash
set -o errexit -o nounset -o pipefail
../bin/build.sh $@
