rootdir := ..

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output dk-vars.mk dakota.build)
target := lib$(target).$(so_ext)

.PRECIOUS: %.project

.PHONY:\
 all\
 check\
 check-exe\
 clean\
 install\
 uninstall\

all: $(target)

$(target): $(srcs)

check: all

check-exe: all

clean:
	$(RM) $(RMFLAGS) $(target) $(target).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dk-compiler.mk dk-vars.mk

install-dirs := $(DESTDIR)$(INSTALL_PREFIX)/bin $(DESTDIR)$(INSTALL_PREFIX)/include $(DESTDIR)$(INSTALL_PREFIX)/lib

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install.files)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files)
