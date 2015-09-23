rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

dirs := $(dir $(wildcard ./*/Makefile))
exes := $(patsubst %,%/exe, $(dirs))

%/exe: %/exe.dk
	dakota --directory $* --output exe exe.dk /usr/local/lib/libdakota-util.$(so_ext)

.PHONY: all check clean

all: $(exes)

check: all
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

clean:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
