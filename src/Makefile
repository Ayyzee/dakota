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
cxx_debug_symbols_ext ?=

include $(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota-info    --output $(objdir)/dakota-info-project.mk    $(srcdir)/dakota-info-project.rep)
include $(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota      --output $(objdir)/libdakota-project.mk      $(srcdir)/libdakota-project.rep)
include $(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota-util --output $(objdir)/libdakota-util-project.mk $(srcdir)/libdakota-util-project.rep)

export EXTRA_LDFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

install_output := $(dakota_info_install) $(libdakota_install) $(libdakota_util_install)

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

$(blddir)/%.dk: $(objdir)/%.tbl

$(objdir)/%.tbl: $(srcdir)/%.sh
	./$<

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --soname $(soname) --output $@ $^

$(DESTDIR)$(prefix)/bin/%: $(srcdir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
$(DESTDIR)$(prefix)/bin/%: $(blddir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)

$(DESTDIR)$(prefix)/lib/%: $(srcdir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)
$(DESTDIR)$(prefix)/lib/%: $(blddir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/%: $(srcdir)/../%
	sudo $(INSTALL_DATA) $< $(@D)
$(DESTDIR)$(prefix)/%: $(blddir)/../%
	sudo $(INSTALL_DATA) $< $(@D)

all: $(dakota_info_output)
	$(MAKE) $(libdakota_output) $(libdakota_util_output)

$(dakota_info_output): $(dakota_info_srcs) $(dakota_info_libs)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(dakota_info_include_dirs) $(CXX_OUTPUT_FLAGS) $@ $^

precompile:
	$(MAKE) --always-make --keep-going DAKOTAFLAGS=--$@ all

INSTALL_DIRS :=\
 $(DESTDIR)$(prefix)/bin\
 $(DESTDIR)$(prefix)/include\
 $(DESTDIR)$(prefix)/lib\
 $(DESTDIR)$(prefix)/lib/dakota\
#

$(INSTALL_DIRS):
	sudo $(INSTALL_DIR) $@

installdirs: $(INSTALL_DIRS)
	$(MAKE) $^

install: $(INSTALL_DIRS)
	$(MAKE) $(install_output)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install_output)

check: all
	$(dakota_info_output) $(libdakota_output) $(libdakota_util_output)
	$(MAKE) --file exes.mk $@
	./$@.sh

clean:
	$(RM) $(RMFLAGS) $(dakota_info_output){.$(cxx_debug_symbols_ext),} $(libdakota_output) $(libdakota_util_output)
	$(RM) $(RMFLAGS) $(objdir)/*
	$(MAKE) --file exes.mk $@
