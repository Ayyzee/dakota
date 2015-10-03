prefix := /usr/local

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA := DK_NO_CONVERT_DASH_SYNTAX=0 DK_TRACE_MACROS=1 $(prefix)/bin/dakota --define-macro DK_TRACE_MACROS=1 --define-macro $(HOST_OS)
DAKOTA_INFO := $(prefix)/bin/dakota-info
