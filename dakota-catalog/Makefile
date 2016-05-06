rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

include $(rootdir)/dakota.mk

include $(shell $(rootdir)/bin/dakota-build2mk --output $(BUILDDIR)/dakota-catalog.mk $(srcdir)/dakota-catalog.build)

# include-dirs
dakota-catalog.include-dirs := $(patsubst %,--include-directory %,$(dakota-catalog.include-dirs))

# should be generated
install-dirs := $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/include $(DESTDIR)$(prefix)/lib/dakota

.PRECIOUS: %.project

.PHONY:\
 all\
 check\
 clean\
 distclean\
 goal-clean\
 install\
 installcheck\
 precompile\
 uninstall\

check: all
	if [[ -e $(rootdir)/lib/libdakota-core.$(so_ext) ]]; then $(dakota-catalog.output) $(rootdir)/lib/libdakota-core.$(so_ext); fi
	if [[ -e $(rootdir)/lib/libdakota.$(so_ext) ]]; then $(dakota-catalog.output) $(rootdir)/lib/libdakota.$(so_ext); fi
	$(dakota-catalog.output) libdl.$(so_ext)

installcheck: check install
	$(MAKE) $(MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(output-files)

clean: goal-clean
	$(RM) $(RMFLAGS) $(dakota-catalog.output).$(cxx_debug_symbols_ext)

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(prefix)/{bin,include,lib/dakota/compiler-{clang,gcc}}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

$(DESTDIR)$(prefix)/lib/dakota/platform.json: $(DESTDIR)$(prefix)/lib/dakota/platform-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(prefix)/lib/dakota/compiler: $(DESTDIR)$(prefix)/lib/dakota/compiler-$(compiler)
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

install-links := $(DESTDIR)$(prefix)/lib/dakota/compiler $(DESTDIR)$(prefix)/lib/dakota/platform.json

install: all $(install-dirs) $(install-files) $(install-links)

precompile:
	$(MAKE) $(MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/compiler
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/platform.json
	#if [[ -d $(DESTDIR)$(prefix)/lib/dakota ]]; then sudo rmdir $(DESTDIR)$(prefix)/lib/dakota; fi
