SHELL := /bin/sh -u

DESTDIR ?=

srcdir ?= .
blddir := .
objdir := $(blddir)/obj

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

--all--: all

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk

include $(shell $(srcdir)/../bin/dakota-json2mk --output /tmp/compiler.mk $(srcdir)/../lib/dakota/compiler.json)

include $(srcdir)/../rules.mk

exes := $(blddir)/tst $(blddir)/min $(blddir)/dummy

all: $(exes)

check: all
	for exe in $(exes); do echo $$exe; $$exe; done

clean:
	rm -f $(exes)
	for exe in $(exes); do rm -fr $$exe.$(cxx_debug_symbols_ext); rm -fv $(objdir)/{nrt,rt,}/$$exe{-main,}.*; done
	rm -f $(blddir)/dummy

$(blddir)/tst:   $(blddir)/../lib/libdakota-util.$(so_ext)

$(blddir)/min:   $(blddir)/../lib/libdakota.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
