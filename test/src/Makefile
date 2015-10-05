rootdir := ../..
prefix := /usr/local

include $(rootdir)/test/vars.mk
include $(rootdir)/test/project-vars.mk

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/project.mk    $(srcdir)/project.rep)

../bin/%: %
	cp $< $@

include $(rootdir)/test/rules.mk
include $(rootdir)/test/project-targets.mk

install: $(install-files)
