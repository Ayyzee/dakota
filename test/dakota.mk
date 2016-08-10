SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir := ..
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 check-exe \
 clean \
 install \
 no-project \
 uninstall \

all \
check \
clean \
no-project:
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) --directory lib $@
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) --directory exe $@

check-exe: check
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) --directory exe $@

install: all
uninstall:
