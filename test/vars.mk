include $(rootdir)/config.mk
include $(rootdir)/vars.mk

#should_pass_dirs := $(dir $(wildcard should-pass/*/Makefile))
#should_fail_dirs := $(dir $(wildcard should-fail/*/Makefile))

target := $(shell $(prefix)/bin/dakota-project --var SO_EXT=$(SO_EXT) name)
prereq := $(shell $(prefix)/bin/dakota-project --var SO_EXT=$(SO_EXT) srcs)
prereq += $(shell $(prefix)/bin/dakota-project --var SO_EXT=$(SO_EXT) libs)

DAKOTA := DKT_FIXUP_STDERR=1 ../../../bin/dakota
