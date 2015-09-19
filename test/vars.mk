include $(rootdir)/config.mk
include $(rootdir)/vars.mk

#should_pass_dirs := $(dir $(wildcard should-pass/*/Makefile))
#should_fail_dirs := $(dir $(wildcard should-fail/*/Makefile))

target := $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) name)
prereq := $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) srcs)
prereq += $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) libs)

DAKOTA := $(prefix)/bin/dakota --define-macro $(DK_HOST_OS)
