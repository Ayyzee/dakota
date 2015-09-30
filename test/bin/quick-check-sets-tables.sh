#!/bin/bash

set -o nounset -o errexit -o pipefail

bin/quick-check.sh should-pass/pass/*{set,table}*
