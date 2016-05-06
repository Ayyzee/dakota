SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir ?= .
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
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
clean \
dist \
distclean \
goal-clean \
install \
installcheck \
precompile \
uninstall:
	$(MAKE) -$(MAKEFLAGS) --directory $(rootdir)/dakota-catalog $@
	$(MAKE) -$(MAKEFLAGS) --directory $(rootdir)/dakota-core $@
	$(MAKE) -$(MAKEFLAGS) --directory $(rootdir)/dakota $@
