rootdir := ../../..
include $(rootdir)/vars.mk

all:
	g++ -Wall -g -o ./exe exe.cc

check:
	./exe $(rootdir)/lib/libdakota.$(SO_EXT)
	#./exe /bin/ls

clean:
	rm -f ./exe *~
