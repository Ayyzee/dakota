include $(rootdir)/config.mk
include $(rootdir)/vars.mk

#should_pass_dirs := $(dir $(wildcard should-pass/*/Makefile))
#should_fail_dirs := $(dir $(wildcard should-fail/*/Makefile))

#export DK_ABS_PATH :=

#target := $(shell dk-project --var SO_EXT=$(SO_EXT) --abs-path name)
#prereq := $(shell dk-project --var SO_EXT=$(SO_EXT) --abs-path files)

target := $(shell dk-project --var SO_EXT=$(SO_EXT) name)
prereq := $(shell dk-project --var SO_EXT=$(SO_EXT) files)
