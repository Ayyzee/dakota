rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

include $(rootdir)/dakota.mk

include $(shell $(rootdir)/bin/dakota-build2mk --output $(BUILDDIR)/libdakota-core.mk $(srcdir)/libdakota-core.build)

# include-dirs
libdakota-core.include-dirs := $(patsubst %,--include-directory %,$(libdakota-core.include-dirs))

# macros
libdakota-core.macros := $(patsubst %,--define-macro %,$(libdakota-core.macros))

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

$(srcdir)/strerror-name.dk: $(srcdir)/strerror-name.tbl

libdakota-core.single: $(libdakota-core.inputs) | libdakota-core.project
	for input in $(libdakota-core.inputs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) --compile --nodefaultlibs --define-macro DKT_WORKAROUND --define-macro HAVE_CONFIG_HH --include-directory . --include-directory ../include --project libdakota-core.project --output $(libdakota-core.builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --shared --nodefaultlibs --define-macro DKT_WORKAROUND --define-macro HAVE_CONFIG_HH --include-directory . --include-directory ../include --project libdakota-core.project

check: all
	../bin/dakota-catalog --silent $(libdakota-core.output)
	echo "func main() ->int-t { return 0; }" > exe.dk; rm -f exe exe.project; $(DAKOTA-BASE) exe.dk; ./exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(output-files)

clean: goal-clean
	if [[ -e libdakota-core.project ]]; then $(DAKOTA-BASE) --clean --project libdakota-core.project; fi
	$(RM) $(RMFLAGS) libdakota-core.project
	$(RM) $(RMFLAGS) libdakota-core.project.io
	$(RM) $(RMFLAGS) exe exe.dk exe.project
	$(RM) $(RMFLAGS) $(srcdir)/strerror-name.tbl

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
