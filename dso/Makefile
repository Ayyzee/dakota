rootdir := ..

builddir := $(shell $(rootdir)/bin/dakota-build builddir build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/build.mk build)

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
	$(RM) $(RMFLAGS) $(target) project
	$(RM) $(RMFLAGS) $(builddir)/build.mk
	$(RM) $(RMFLAGS) $(builddir)

install-dirs := $(DESTDIR)$(prefix)/{include,lib}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install-files)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
