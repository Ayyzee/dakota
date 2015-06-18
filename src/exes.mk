SHELL := /bin/sh -u

srcdir ?= .
blddir := .
objdir := $(blddir)/obj

include $(shell $(srcdir)/../bin/dakota-json2mk --output /tmp/compiler.mk $(srcdir)/../lib/dakota/compiler.json)

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk
include $(srcdir)/../rules.mk

export EXTRA_LDFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

include_dirs := --include-directory ../include

$(blddir)/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory ../include --output $@ $^

exes := $(blddir)/tst $(blddir)/min $(blddir)/dummy

all: $(exes)

check: all
	for exe in $(exes); do echo $$exe; $$exe; done

clean:
	rm -f $(exes)
	for exe in $(exes); do rm -fr $$exe.$(cxx_debug_symbols_ext); rm -fv $(objdir)/{nrt,rt,}/$$exe{-main,}.*; done
	rm -f $(blddir)/dummy

$(blddir)/tst: $(blddir)/../lib/libdakota-util.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(include_dirs) $(CXX_OUTPUT_FLAGS) $@ $^
