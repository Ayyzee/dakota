#!/bin/bash

set -o errexit -o nounset -o pipefail

./generate-compiler-default-argument-promotions.pl
