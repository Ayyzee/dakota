SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%: %.dk
	$(MAKE) --directory $(dir $@) all

.PHONY: all check clean

$(shell ./generate-phony-targets.sh)

include phony-targets.mk
