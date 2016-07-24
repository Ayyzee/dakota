SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir ?= .
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 check-exe \
 clean \
 dist \
 distclean \
 goal-clean \
 install \
 installcheck \
 precompile \
 uninstall \

all:
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota all install

uninstall:
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core $@

check \
check-exe \
clean \
dist \
distclean \
goal-clean \
install \
installcheck \
precompile:
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/test $@
