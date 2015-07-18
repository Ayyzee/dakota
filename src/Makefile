rootdir := ..

include $(rootdir)/dakota.mk

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/dakota-info-project.mk    $(srcdir)/dakota-info-project.rep)
include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/libdakota-project.mk      $(srcdir)/libdakota-project.rep)
include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/libdakota-util-project.mk $(srcdir)/libdakota-util-project.rep)

# include-dirs
dakota-info.include-dirs :=    $(patsubst %,--include-directory %,$(dakota-info.include-dirs))
libdakota.include-dirs :=      $(patsubst %,--include-directory %,$(libdakota.include-dirs))
libdakota-util.include-dirs := $(patsubst %,--include-directory %,$(libdakota-util.include-dirs))

# macros
#dakota-info_macros :=
libdakota.macros :=      $(patsubst %,--define-macro %,$(libdakota.macros))
libdakota-util.macros := $(patsubst %,--define-macro %,$(libdakota-util.macros))

# should be generated
install_dirs := $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/include $(DESTDIR)$(prefix)/lib/dakota

.PHONY:\
 all\
 check\
 clean\
 install\
 installdirs\
 precompile\
 uninstall\

$(libdakota.output) $(libdakota-util.output): $(dakota-info.output)
$(libdakota-util.output): $(libdakota.output)

check: all
	$(dakota-info.output) $(libdakota.output) $(libdakota-util.output)
	$(MAKE) $(MAKEFLAGS) --file exes.mk $@
	./$@.sh

clean:
	$(RM) $(RMFLAGS) aaa.dk
	$(RM) $(RMFLAGS) $(output-files)
	$(RM) $(RMFLAGS) $(dakota-info.output).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(objdir)/*
	$(MAKE) $(MAKEFLAGS) --file exes.mk $@

goal-clean:
	$(RM) $(RMFLAGS) $(output-files)

installdirs: # to support --jobs these must be done serially
	for dir in $(install-dirs); do sudo $(INSTALL_DIR) $$dir; done

$(install-files): installdirs

install: $(install-files)

precompile:
	$(MAKE) $(MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
