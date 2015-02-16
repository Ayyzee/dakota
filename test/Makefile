SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%/exe: %/exe.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) --directory $(dir $@) $(notdir $@)

.PHONY: all check clean

all_should_pass   := all-should-pass.mk
check_should_pass := check-should-pass.mk

$(shell ./generate-phony-targets-1.sh all-should-pass   should-pass > $(all_should_pass))
$(shell ./generate-phony-targets-2.sh check-should-pass should-pass > $(check_should_pass))

all: all-should-pass

include $(all_should_pass)

check: check-should-pass

include $(check_should_pass)

clean:
	rm -rf $(all_should_pass) $(check_should_pass) should-{pass,fail}/*/{exe,obj,lib-{1,2,3}.$(SO_EXT)}
