#!/bin/sh -u

find $1 -name .svn -type d -exec rm -rf {} \;
find $1 -name "*.tar" -type f -exec rm -f {} \;

tar zcf $1.tar.gz $1
