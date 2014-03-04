rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%: %.dk
	dakota --output $@ $^ /usr/local/lib/libdakota-util.$(SO_EXT)

.PHONY: all check clean

all: exe

check: all
	./exe

clean:
	rm -rf obj
	rm -f exe
	rm -f *~
