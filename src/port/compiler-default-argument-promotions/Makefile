rootdir := ../../..
prefix := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

EXTRA_CXXFLAGS += --include-directory . --warn-error

DAKOTA := DK_NO_LINE=0 DK_NO_CONVERT_DASH_SYNTAX=0 DK_ENABLE_TRACE_MACROS=1 $(prefix)/bin/dakota --define-macro DK_ENABLE_TRACE_MACROS=1 --define-macro $(HOST_OS)
DAKOTA_INFO := $(prefix)/bin/dakota-info

include $(rootdir)/test/project-vars.mk
include $(rootdir)/test/rules.mk
include $(rootdir)/test/project-targets.mk
