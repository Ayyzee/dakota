#rootdir := ../../..
#include $(rootdir)/config.mk
#include $(rootdir)/vars.mk

all:
	clang++ -std=c++11 --debug=3 -Weverything -Wno-c++98-compat --output exe exe.cc

check: all
	./exe

clean:
	rm -rf exe exe.dSYM *~
