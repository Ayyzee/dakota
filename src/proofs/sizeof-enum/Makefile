rootdir := ../../..
include $(rootdir)/vars.mk

all:
	g++ -Wall -g -o exe exe.cc

check: all
	./exe

clean:
	rm -rf obj
	rm -f exe *~
