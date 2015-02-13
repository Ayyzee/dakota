SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%: %.dk
	$(MAKE) --directory $(dir $@) $(notdir $@)

phony := all check clean
.PHONY: $(phony)
phony_targets := phony-targets.mk
$(shell ./generate-phony-targets.sh $(phony) > $(phony_targets))
include $(phony_targets)
