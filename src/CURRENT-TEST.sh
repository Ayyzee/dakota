#!/bin/bash

set -o nounset -o errexit -o pipefail

make --directory ../test/should-pass/pass/tst clean all check
