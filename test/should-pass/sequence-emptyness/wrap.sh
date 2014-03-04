#!/bin/sh -u

./exe > $1 2>&1

cat /dev/null > $1.dot

echo "digraph" >> $1.dot
echo "{" >> $1.dot
echo "  graph [ rankdir = \"LR\" ];" >> $1.dot
echo "  graph [ margin = \"0.25\" ];" >> $1.dot
echo "  graph [ page = \"8.5,11\" ];" >> $1.dot
echo "  graph [ size = \"8,10.5\" ];" >> $1.dot
cat $1 >> $1.dot
echo "}" >> $1.dot
