#!/bin/sh

str="bar"
echo ${str:0:1}
echo ${str:1:1}
echo ${str:2:1}

len=${#str}
(( len-- ))
result=''
d=''
for i in `seq 0 $len`; do
    echo ${str:$i:1}
done
