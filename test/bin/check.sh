#!/bin/bash

set -o errexit -o nounset -o pipefail

path=check-history/should-pass-pass-$$.txt
echo $path >> check-history/should-pass-pass-order.txt
bin/check.pl --output $path should-pass/pass/*/
cat check-history/should-pass-pass-$$.txt
#
#
