#!/bin/sh -u

cc-from-dk.pl < $1 > /tmp/$1.cc
opendiff /tmp/$1.cc obj/$1.cc
