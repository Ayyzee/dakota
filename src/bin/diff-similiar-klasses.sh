#!/bin/bash

#set -o errexit -o nounset -o pipefail
set -o nounset -o pipefail

num_lines=$(diff --minimal sorted-counted-set.dk hashed-counted-set.dk | wc -l)
echo $num_lines diff sorted-counted-set.dk hashed-counted-set.dk
num_lines=$(diff --minimal sorted-table.dk       hashed-table.dk | wc -l)
echo $num_lines diff sorted-table.dk hashed-table.dk
num_lines=$(diff --minimal table.dk              counted-set.dk | wc -l)
echo $num_lines diff table.dk counted-set.dk
num_lines=$(diff --minimal sorted-ptr-array.hh   sorted-array.hh | wc -l)
echo $num_lines diff sorted-array.hh sorted-ptr-array.hh
num_lines=$(diff --minimal sorted-array.dk   sorted-ptr-array.dk | wc -l)
echo $num_lines diff sorted-array.dk sorted-ptr-array.dk
