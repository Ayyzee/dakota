SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%: %.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) --directory $(dir $@) $(notdir $@)

.PHONY: all check clean

all   := all.mk
check := check.mk

$(shell ./generate-phony-targets-1.sh all   > $(all))
$(shell ./generate-phony-targets-2.sh check > $(check))

include $(all)

include $(check)

clean:
	rm -rf $(all) $(check) should-pass/*/{exe,obj,lib-{1,2,3}.$(SO_EXT)}
