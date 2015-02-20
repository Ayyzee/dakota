SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%/exe: %/exe.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

%/exe: %/exe.cc
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

.PHONY: all check clean

all_should_pass   := all-should-pass.mk
check_should_pass := check-should-pass.mk

$(shell ./generate-phony-targets-1.sh all   should-pass > $(all_should_pass))
$(shell ./generate-phony-targets-2.sh check should-pass > $(check_should_pass))

include $(all_should_pass)

include $(check_should_pass)

clean:
	rm -rf $(all_should_pass) $(check_should_pass) should-{pass,fail}/*/{exe,obj,failed-{build,check},lib-{1,2,3}.$(SO_EXT)}
