#!/bin/bash

set -o errexit -o nounset -o pipefail

bin/check.pl --output check-history/should-pass-pass-$$.txt should-pass/pass/*/
cat check-history/should-pass-pass-$$.txt
#
#
