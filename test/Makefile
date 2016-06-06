SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir := ..
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 clean \
 no-project \

all \
check \
clean \
no-project:
	time $(MAKE) $(MAKEFLAGS) --directory lib $@
	time $(MAKE) $(MAKEFLAGS) --directory exe $@

install:
