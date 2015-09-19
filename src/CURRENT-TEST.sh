#!/bin/bash

set -o nounset -o errexit -o pipefail

rm -f empty-klass-x && make empty-klass-x && ./empty-klass-x
