rootdir := ../../../..

include $(rootdir)/test/vars.mk
#include $(rootdir)/test/project-vars.mk
include $(rootdir)/test/rules.mk
#include $(rootdir)/test/project-targets.mk

all:
	$(prefix)/bin/dakota-info $(prefix)/lib/libdakota.dylib >      libdakota.dk
	$(prefix)/bin/dakota-info $(prefix)/lib/libdakota-util.dylib > libdakota-util.dk
	$(prefix)/bin/dakota --compile --define-macro __darwin__ --output libdakota.$(o_ext)      libdakota.dk
	$(prefix)/bin/dakota --compile --define-macro __darwin__ --output libdakota-util.$(o_ext) libdakota.dk libdakota-util.dk

clean:
	rm -f {libdakota,libdakota-util}.{dk,$(o_ext)}
	rm -fr obj

check:
