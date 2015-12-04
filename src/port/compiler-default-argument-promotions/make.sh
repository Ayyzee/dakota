#!/bin/bash

set -o errexit -o nounset -o pipefail

#clang++ -std=c++11 --output type-index type-index-main.cc

#clang++ --compile -std=c++11 --warn-varargs --warn-error test.cc

./generate-compiler-default-argument-promotions.pl
