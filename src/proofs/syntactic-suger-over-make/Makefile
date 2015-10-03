#rootdir := ../../..
#include $(rootdir)/config.mk
#include $(rootdir)/vars.mk

all:
	clang++ -std=c++11 --debug=3 --no-warnings --output exe-cc exe-main.cc

check: all
	./exe-cc

clean:
	rm -rf exe-cc exe-cc.dSYM *~
