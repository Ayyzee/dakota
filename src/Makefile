SHELL := /bin/sh -u

DESTDIR ?=

srcdir ?= .
blddir := .
objdir := $(blddir)/obj

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

--all--: all

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk

include $(shell $(srcdir)/../bin/dakota-json2mk --output $(objdir)/compiler.mk $(srcdir)/../lib/dakota/compiler.json)

include $(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota-info    --output $(objdir)/dakota-info-project.mk    $(srcdir)/dakota-info-project.rep)
include $(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota      --output $(objdir)/libdakota-project.mk      $(srcdir)/libdakota-project.rep)
include $(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota-util --output $(objdir)/libdakota-util-project.mk $(srcdir)/libdakota-util-project.rep)

include $(srcdir)/../rules.mk

output_files := $(dakota_info_output) $(libdakota_output) $(libdakota_util_output)

install_files := $(dakota_info_install) $(libdakota_install) $(libdakota_util_install)
install_dirs := $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/include $(DESTDIR)$(prefix)/lib/dakota

# include-dirs
dakota_info_include_dirs :=    $(patsubst %,--include-directory %,$(dakota_info_include_dirs))
libdakota_include_dirs :=      $(patsubst %,--include-directory %,$(libdakota_include_dirs))
libdakota_util_include_dirs := $(patsubst %,--include-directory %,$(libdakota_util_include_dirs))

# macros
dakota_info_macros :=    $(patsubst %,--define-macro %,$(dakota_info_macros))
libdakota_macros :=      $(patsubst %,--define-macro %,$(libdakota_macros))
libdakota_util_macros := $(patsubst %,--define-macro %,$(libdakota_util_macros))

.PHONY:\
 --all--\
 all\
 check\
 clean\
 install\
 installdirs\
 precompile\
 uninstall\

all: $(dakota_info_output)
	$(MAKE) $(libdakota_output) $(libdakota_util_output)

check: all
	$(dakota_info_output) $(libdakota_output) $(libdakota_util_output)
	$(MAKE) --file exes.mk $@
	./$@.sh

clean:
	$(RM) $(RMFLAGS) $(output_files)
	$(RM) $(RMFLAGS) $(dakota_info_output).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) $(objdir)/*
	$(MAKE) --file exes.mk $@

installdirs: # to support --jobs these must be done serially
	for dir in $(install_dirs); do sudo $(INSTALL_DIR) $$dir; done

$(install_files): installdirs

install: $(install_files)

precompile:
	$(MAKE) --always-make --keep-going DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install_files)
