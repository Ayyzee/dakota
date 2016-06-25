rootdir := ..

target-base := dso
builddir := $(shell $(rootdir)/bin/dakota-build builddir $(target-base).build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/$(target-base).mk $(target-base).build)

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
	$(RM) $(RMFLAGS) $(builddir)/$(target-base).mk
	$(RM) $(RMFLAGS) $(builddir)

install-dirs := $(DESTDIR)$(prefix)/{include,lib}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install-files)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
