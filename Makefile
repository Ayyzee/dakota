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
uninstall:
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-find-library $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota-core $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/dakota $@
	time $(MAKE) $(MAKEFLAGS) --directory $(rootdir)/test $@
