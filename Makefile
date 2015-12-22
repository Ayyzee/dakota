SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir ?= .
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 clean \
 dist \
 distclean \
 install \
 precompile \
 uninstall \

all \
check \
clean \
dist \
install \
precompile \
uninstall:
	$(MAKE) -$(MAKEFLAGS) --directory $(rootdir)/src $@

distclean: clean
	cd $(rootdir); ./configure-common
