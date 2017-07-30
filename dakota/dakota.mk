rootdir := ..

SOURCE_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output dk-vars.mk dakota.build)
target := lib$(target).$(so_ext)

.PRECIOUS: %.project

.PHONY:\
 all\
 clean\
 install\
 uninstall\

all: $(target)

$(target): $(srcs)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files) $(install-links)

install-dirs :=  $(INSTALL_PREFIX)/bin $(INSTALL_PREFIX)/include $(INSTALL_PREFIX)/lib/dakota
install-links :=

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install.files) $(install-links)

clean: | dakota.project
	$(DAKOTA-BASE) --project dakota.project --clean
	$(RM) $(RMFLAGS) $(target)
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dk-compiler.mk dk-vars.mk
