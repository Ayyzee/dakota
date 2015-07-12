#rootdir := ../../..
#include $(rootdir)/config.mk
#include $(rootdir)/vars.mk

so_ext := dylib

all:
	clang++ -std=c++11 -Weverything -Wno-c99-extensions -Wno-c++98-compat-pedantic --output exe exe.cc

check: all
	./exe

clean:
	rm -rf exe exe.dSYM *~
