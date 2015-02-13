SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

.PHONY: all check clean

$(shell ./generate-phony-targets.sh all check clean > phony-target.mk)

include phony-targets.mk
