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
	sudo true # so password prompt is immediate
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso all install
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog all install
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core all install
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota all install

uninstall:
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core $@

check \
check-exe \
clean \
dist \
distclean \
goal-clean \
install \
installcheck \
precompile:
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dso $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota $@
	$(MAKE) $(MAKEFLAGS) --directory $(rootdir)/test $@
