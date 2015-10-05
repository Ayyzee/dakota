#!/bin/bash

set -o nounset -o errexit -o pipefail

DK_ENABLE_TRACE=1 ../../../bin/run-with-timeout 3 ./exe
