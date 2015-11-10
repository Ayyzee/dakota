#!/bin/bash

set -o errexit -o nounset -o pipefail

date; make clean; make -k -j 4 > /dev/null || true; bin/check.sh; date
