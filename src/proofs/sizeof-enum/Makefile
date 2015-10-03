rootdir := ../../..
include $(rootdir)/vars.mk

all:
	g++ -Wall -g -o exe-cc exe-main.cc

check: all
	./exe-cc

clean:
	rm -rf obj
	rm -f exe-cc *~
