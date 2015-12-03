#!/bin/bash

set -o nounset -o errexit -o pipefail

hash-all()
{
    bname=$(basename $1 .txt)
    xargs ./example-test < $1 > hashes-$bname.txt
    sort -u hashes-$bname.txt > hashes-$bname-sorted-unique.txt
    wc -l hashes-$bname.txt
    wc -l hashes-$bname-sorted-unique.txt
}

hash-all /usr/share/dict/words

echo;
number=$(wc -l /usr/share/dict/words)
./numbers.sh $number > numbers.txt

hash-all numbers.txt
