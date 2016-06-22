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
	time $(MAKE) $(MAKEFLAGS) --directory lib $@
	time $(MAKE) $(MAKEFLAGS) --directory exe $@

check-exe: check
	time $(MAKE) $(MAKEFLAGS) --directory exe $@

install: all
uninstall:
