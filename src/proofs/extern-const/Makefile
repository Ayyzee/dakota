#rootdir := ../../..
#include $(rootdir)/config.mk
#include $(rootdir)/vars.mk

so_ext := dylib

all:
	clang++ -std=c++11 -Weverything --output exe exe.cc
	clang++ -std=c++11 -Weverything --shared -fPIC -o lib-1.$(so_ext) lib-1.cc

check: all
	./exe
	../../bin/nm.sh lib-1.$(so_ext)

clean:
	rm -rf exe exe.dSYM *~
