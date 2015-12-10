SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir := .
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 clean \
 install \
 precompile \
 uninstall \

all \
check \
clean \
install \
precompile \
uninstall:
	$(MAKE) -$(MAKEFLAGS) --directory src $@
