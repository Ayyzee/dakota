rootdir := ..

include $(rootdir)/common.mk

target-base := dso
include $(shell $(rootdir)/bin/dakota-build2mk --output $(BUILDDIR)/$(target-base).mk $(srcdir)/$(target-base).build)

.PHONY:\
 all\
 check\
 check-exe\
 clean\
 install\
 uninstall\

all: $(target)

check: all

check-exe: all

clean:
	$(RM) $(RMFLAGS) $(target)
	$(RM) $(RMFLAGS) $(BUILDDIR)/$(target-base).mk
	$(RM) $(RMFLAGS) $(builddir)

install-dirs := $(DESTDIR)$(prefix)/{include,lib}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install-files)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
