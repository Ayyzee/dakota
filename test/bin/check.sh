#!/bin/bash

set -o errexit -o nounset -o pipefail

bin/check.pl should-pass/pass/*/
#
#
