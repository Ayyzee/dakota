DK_PREFIX ?= ../../..

SO_EXT := dylib

DOT := dot
DAKOTA := dakota

dot_files := $(wildcard *.dot)
png_files := $(dot_files:.dot=.png)

name :=  $(shell $(DK_PREFIX)/bin/dakota-project name  --var SO_EXT=$(SO_EXT))
files := $(shell $(DK_PREFIX)/bin/dakota-project files --var SO_EXT=$(SO_EXT))
