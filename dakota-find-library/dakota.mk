rootdir := ..

SOURCE_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output dk-vars.mk dakota.build)

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
	$(RM) $(RMFLAGS) $(target).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dk-compiler.mk dk-vars.mk

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(INSTALL_PREFIX)/bin $(DESTDIR)$(INSTALL_PREFIX)/include $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform.json:              $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json: $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler-command-line-$(compiler).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

install-links := $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/platform.json

install: all $(install-dirs) $(install.files) $(install-links)

precompile:
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files) $(install-file-links)
