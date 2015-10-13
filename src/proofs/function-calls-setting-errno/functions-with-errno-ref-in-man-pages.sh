#!/bin/bash

set -o errexit -o nounset -o pipefail

sections="2 3"
for section in $sections; do
    for file in $(grep -l errno /usr/share/man/man$section/*.$section); do
        name=$(basename $file .$section)
        echo $name
    done
done
