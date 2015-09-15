SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%/exe: %/exe.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

%/exe: %/exe.cc
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

.PHONY: all clean

all-should-pass := $(shell ./bin/generate-phony-targets-1.sh should-pass)
all-should-fail := $(shell ./bin/generate-phony-targets-1.sh should-fail)

all: $(all-should-pass) $(all-should-fail)

clean:
	rm -f  should-{pass,fail}/*/{exe,lib-{1,2,3}.$(so_ext)}
	rm -fr should-{pass,fail}/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	rm -f  should-{pass,fail}/*/failed-build
	rm -fr should-{pass,fail}/*/$(objdir)
