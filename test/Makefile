SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir := ..
include $(rootdir)/makeflags.mk

.PHONY: \
 all \
 check \
 clean \

all \
check \
clean:
	time $(MAKE) -$(MAKEFLAGS) --directory lib $@
	time $(MAKE) -$(MAKEFLAGS) --directory exe $@
