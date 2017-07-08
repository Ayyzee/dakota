rootdir := ..

SOURCE_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/default.mk dakota.build)

.PRECIOUS: %.project

.PHONY:\
 all\
 check\
 check-exe\
 clean\
 distclean\
 goal-clean\
 install\
 installcheck\
 precompile\
 uninstall\

all: $(target)

$(target): $(srcs)

check-exe: all
	$(target) libssl.$(so_ext)

check: all
	if [[ -e $(rootdir)/lib/libdakota-core.$(so_ext) ]]; then $(target) $(rootdir)/lib/libdakota-core.$(so_ext); fi
	if [[ -e $(rootdir)/lib/libdakota.$(so_ext) ]]; then $(target) $(rootdir)/lib/libdakota.$(so_ext); fi
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target)

clean: goal-clean
	$(RM) $(RMFLAGS) $(target).$(cxx_debug_symbols_ext) dakota.project
	$(RM) $(RMFLAGS) $(builddir)

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(INSTALL_PREFIX)/bin $(DESTDIR)$(INSTALL_PREFIX)/include $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler-$(compiler)

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform.json: $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler: $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler-$(compiler)
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

install-dir-links :=  $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler
install-file-links := $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform.json
install-links := $(install-dir-links) $(install-file-links)

install: all $(install-dirs) $(install.files) $(install-links)

precompile:
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files) $(install-file-links)
