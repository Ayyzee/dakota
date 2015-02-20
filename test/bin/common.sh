#!/bin/bash

set -o nounset -o errexit -o pipefail

paths-from-pattern()
{
    pattern="$1"
    paths=$(echo $pattern)
    if [[ "$pattern" == "$paths" ]]; then
        paths=""
    fi
    echo $paths
}
