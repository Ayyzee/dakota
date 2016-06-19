rootdir := ..

include $(rootdir)/common.mk

project := dso

include $(shell $(rootdir)/bin/dakota-build2mk --output $(BUILDDIR)/$(project).mk $(srcdir)/$(project).build)

.PHONY:\
 all\
 clean\

all: $(target)

clean:
	$(RM) $(RMFLAGS) $(target)
	$(RM) $(RMFLAGS) $(BUILDDIR)/$(project).mk
	$(RM) $(RMFLAGS) $(builddir)
