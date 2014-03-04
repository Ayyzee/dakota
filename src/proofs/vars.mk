DK_PREFIX ?= ../../..

SO_EXT := dylib

DOT := dot
DAKOTA := dakota

dot_files := $(wildcard *.dot)
png_files := $(dot_files:.dot=.png)

name :=  $(shell $(DK_PREFIX)/bin/dk name  --var SO_EXT=$(SO_EXT))
files := $(shell $(DK_PREFIX)/bin/dk files --var SO_EXT=$(SO_EXT))
