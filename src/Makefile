rootdir := ..

include $(rootdir)/dakota.mk

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/dakota-info-project.mk    $(srcdir)/dakota-info-project.json)
include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/libdakota-project.mk      $(srcdir)/libdakota-project.json)
include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/libdakota-util-project.mk $(srcdir)/libdakota-util-project.json)

# include-dirs
dakota-info.include-dirs :=    $(patsubst %,--include-directory %,$(dakota-info.include-dirs))
libdakota.include-dirs :=      $(patsubst %,--include-directory %,$(libdakota.include-dirs))
libdakota-util.include-dirs := $(patsubst %,--include-directory %,$(libdakota-util.include-dirs))

# macros
#dakota-info.macros :=
libdakota.macros :=      $(patsubst %,--define-macro %,$(libdakota.macros))
libdakota-util.macros := $(patsubst %,--define-macro %,$(libdakota-util.macros))

# should be generated
install-dirs := $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/include $(DESTDIR)$(prefix)/lib/dakota

.PHONY:\
 all\
 check\
 clean\
 distclean\
 goal-clean\
 install\
 install-dirs\
 ls-install-files\
 precompile\
 uninstall\

$(libdakota.output) $(libdakota-util.output): $(dakota-info.output)
$(libdakota-util.output): $(libdakota.output)

$(libdakota.output): $(srcdir)/strerror-name.tbl # not ideal, but ...

check: all
	$(dakota-info.output) $(libdakota.output) $(libdakota-util.output)
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(output-files)

clean: goal-clean
	$(RM) $(RMFLAGS) $(srcdir)/strerror-name.tbl
	$(RM) $(RMFLAGS) $(dakota-info.output)
	$(RM) $(RMFLAGS) $(dakota-info.output).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(libdakota.output)
	$(RM) $(RMFLAGS) $(libdakota.output).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(libdakota-util.output)
	$(RM) $(RMFLAGS) $(libdakota-util.output).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(objdir)/*
	if [[ -e $@.sh ]]; then ./$@.sh; fi

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(prefix)/{bin,include,lib/dakota}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

$(DESTDIR)$(prefix)/lib/dakota/platform.json: $(DESTDIR)$(prefix)/lib/dakota/platform-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(prefix)/lib/dakota/compiler.json: $(DESTDIR)$(prefix)/lib/dakota/compiler-$(compiler).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

install-links := $(DESTDIR)$(prefix)/lib/dakota/platform.json $(DESTDIR)$(prefix)/lib/dakota/compiler.json

install: $(install-dirs) $(install-files) $(install-links)

precompile:
	$(MAKE) $(MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files)
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/{compiler,platform}.json
	#if [[ -d $(DESTDIR)$(prefix)/lib/dakota ]]; then sudo rmdir $(DESTDIR)$(prefix)/lib/dakota; fi
