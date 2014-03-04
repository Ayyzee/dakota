#!/bin/sh -u

name=DakotaCore
version=A

mkdir -p $name.framework/Versions/$version/{Headers,Libraries}
mkdir -p $name.framework/Versions/$version/Resources/English.lproj/Documentation
cd $name.framework
ln -s Versions/$version Current
ln -s Current/Headers
ln -s Current/Resources
touch Current/$name
ln -s Current/$name
touch Current/Headers/$name.h
touch Current/Resources/Info.plist
