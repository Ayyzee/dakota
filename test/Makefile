SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%/exe: %/exe.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

%/exe: %/exe.cc
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

.PHONY: all clean

all-should-pass-pass := $(shell ./bin/generate-phony-targets-1.sh should-pass/pass)
all-should-pass-fail := $(shell ./bin/generate-phony-targets-1.sh should-pass/fail)
all-should-fail :=      $(shell ./bin/generate-phony-targets-1.sh should-fail)

all: $(all-should-pass-pass) $(all-should-pass-fail) $(all-should-fail)

clean:
	rm -f  should-pass/{pass,fail}/*/failed-{build,run}
	rm -fr should-pass/{pass,fail}/*/obj
	rm -f  should-pass/{pass,fail}/*/{exe,lib-{1,2,3}.$(so_ext)}
	rm -fr should-pass/{pass,fail}/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	rm -f  should-fail/*/failed-{build,run}
	rm -f  should-fail/*/{exe,lib-{1,2,3}.$(so_ext)}
	rm -fr should-fail/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	rm -fr should-fail/*/obj
