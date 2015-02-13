include $(rootdir)/config.mk
include $(rootdir)/vars.mk

#should_pass_dirs := $(dir $(wildcard should-pass/*/Makefile))
#should_fail_dirs := $(dir $(wildcard should-fail/*/Makefile))

#export DK_ABS_PATH :=

#target := $(shell dakota-project --var SO_EXT=$(SO_EXT) --abs-path name)
#prereq := $(shell dakota-project --var SO_EXT=$(SO_EXT) --abs-path srcs)
#prereq += $(shell dakota-project --var SO_EXT=$(SO_EXT) --abs-path libs)

target := $(shell dakota-project --var SO_EXT=$(SO_EXT) name)
prereq := $(shell dakota-project --var SO_EXT=$(SO_EXT) srcs)
prereq += $(shell dakota-project --var SO_EXT=$(SO_EXT) libs)

DAKOTA := DK_PREFIX=../../.. ../../../bin/dakota

EXTRA_DAKOTAFLAGS := --include-directory .
