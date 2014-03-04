#!/bin/sh -u

for file in $@; do
  ./exe $file | tee "$file-out"
  ./dump.pl < "$file-out"
  rm "$file-out"
done
