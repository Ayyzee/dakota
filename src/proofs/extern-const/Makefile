#rootdir := ../../..
# include $(rootdir)/config.mk
# include $(rootdir)/vars.mk

so_ext := dylib

all:
	clang++ -std=c++11 -Weverything --output exe-cc exe-main.cc
	clang++ -std=c++11 -Weverything --shared -fPIC -o lib-1.$(so_ext) lib-1.cc

check: all
	./exe-cc
	../../bin/nm.sh lib-1.$(so_ext)

clean:
	rm -rf exe-cc exe-cc.dSYM *~
