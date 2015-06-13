SHELL := /bin/sh -u

srcdir ?= .
blddir := .

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

include_dirs := --include-directory ../include

$(blddir)/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory ../include --output $@ $^

all:
	$(MAKE) --file check.mk $(blddir)/tst
	$(blddir)/tst
	rm -f $(blddir)/tst obj/{nrt,rt,}/tst{-main,}.*
	$(MAKE) --file check.mk $(blddir)/min
	$(blddir)/min
	rm -f $(blddir)/min obj/{nrt,rt,}/min{-main,}.*
	$(MAKE) --file check.mk $(blddir)/dummy
	$(blddir)/dummy
	rm -f $(blddir)/dummy

$(blddir)/tst: $(blddir)/../lib/libdakota-util.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(include_dirs) $(CXX_OUTPUT_FLAGS) $@ $^
