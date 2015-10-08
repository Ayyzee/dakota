#!/bin/bash

set -o errexit -o nounset -o pipefail

dirs="should-pass/pass"

for dir in $dirs; do
  grep "summary: " $(ls -r -t check-history/$dir/*.txt)
done
