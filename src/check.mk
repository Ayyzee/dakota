SHELL := /bin/sh -u

DESTDIR ?=

srcdir ?= .
blddir := .

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

$(shell $(srcdir)/../bin/dakota-json2mk --output $(blddir)/../lib/dakota/compiler.mk $(srcdir)/../lib/dakota/compiler.json)
include $(blddir)/../lib/dakota/compiler.mk

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk

export EXTRA_LDFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

$(blddir)/../bin/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

$(blddir)/%:        $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

all:
	$(MAKE) $(blddir)/tst
	$(blddir)/tst
	$(MAKE) $(blddir)/min
	$(blddir)/min
	$(MAKE) $(blddir)/dummy
	$(blddir)/dummy

$(blddir)/tst: $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^
