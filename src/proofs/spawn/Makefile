rootdir := ../../..
include $(rootdir)/vars.mk

all:
	g++ -Wall -g -o ./exe-cc exe-main.cc

check:
	./exe-cc $(rootdir)/lib/libdakota.$(so_ext)
	#./exe-cc /bin/ls

clean:
	rm -f ./exe-cc *~
