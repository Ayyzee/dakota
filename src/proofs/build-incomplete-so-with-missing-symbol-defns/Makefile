rootdir := ../../..

include $(rootdir)/test/vars.mk
include $(rootdir)/test/project-vars.mk

CXX_SHARED_FLAGS += -Wl,-flat_namespace,-undefined,warning # this does not work!

include $(rootdir)/test/rules.mk
include $(rootdir)/test/project-targets.mk
