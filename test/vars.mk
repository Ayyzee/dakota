#prefix := $(HOME)/github/dakota
prefix := /usr/local

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

target := $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) name)
prereq := $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) srcs)
prereq += $(shell $(rootdir)/bin/dakota-project --var so_ext=$(so_ext) libs)

DAKOTA :=      $(prefix)/bin/dakota --define-macro $(HOST_OS)
DAKOTA_INFO := $(prefix)/bin/dakota-info
