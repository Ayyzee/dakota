DK_PREFIX ?= ../../..

so_ext := dylib

DOT := dot
DAKOTA := dakota

dot_files := $(wildcard *.dot)
png_files := $(dot_files:.dot=.png)

name :=  $(shell $(DK_PREFIX)/bin/dakota-project name  --var so_ext=$(so_ext))
files := $(shell $(DK_PREFIX)/bin/dakota-project files --var so_ext=$(so_ext))
