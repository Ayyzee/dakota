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

$(blddir)/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory ../include --output $@ $^

all:
	$(MAKE) --file check.mk $(blddir)/tst
	$(blddir)/tst
	$(MAKE) --file check.mk $(blddir)/min
	$(blddir)/min
	$(MAKE) --file check.mk $(blddir)/dummy
	$(blddir)/dummy

$(blddir)/tst: $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) --include-directory ../include $(CXX_OUTPUT_FLAGS) $@ $^
