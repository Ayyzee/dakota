SHELL := /bin/sh -u

DESTDIR ?=

srcdir ?= .
blddir := .

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

$(shell $(srcdir)/../bin/dakota-json2mk --output $(blddir)/../lib/dakota/compiler.mk $(srcdir)/../lib/dakota/compiler.json)
include $(blddir)/../lib/dakota/compiler.mk

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk

export EXTRA_LDFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota-info    --output $(blddir)/dakota-info-project.mk    $(srcdir)/dakota-info-project.rep)
$(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota      --output $(blddir)/libdakota-project.mk      $(srcdir)/libdakota-project.rep)
$(shell $(srcdir)/../bin/dakota-json2mk --prefix libdakota-util --output $(blddir)/libdakota-util-project.mk $(srcdir)/libdakota-util-project.rep)

__all__: all

include $(blddir)/dakota-info-project.mk
dakota_info_install = $(dakota_info_install_includes) $(dakota_info_install_libs) $(dakota_info_install_bins)
install_output += $(dakota_info_install)

include $(blddir)/libdakota-project.mk
libdakota_install = $(libdakota_install_includes) $(libdakota_install_libs) $(libdakota_install_bins)
install_output += $(libdakota_install)

include $(blddir)/libdakota-util-project.mk
libdakota_util_install = $(libdakota_util_install_includes) $(libdakota_util_install_libs) $(libdakota_util_install_bins)
install_output += $(libdakota_util_output)

# include-dirs
dakota_info_include_dirs :=    $(patsubst %,--include-directory %,$(dakota_info_include_dirs))
libdakota_include_dirs :=      $(patsubst %,--include-directory %,$(libdakota_include_dirs))
libdakota_util_include_dirs := $(patsubst %,--include-directory %,$(libdakota_util_include_dirs))

# macros
dakota_info_macros :=    $(patsubst %,--define-macro %,$(dakota_info_macros))
libdakota_macros :=      $(patsubst %,--define-macro %,$(libdakota_macros))
libdakota_util_macros := $(patsubst %,--define-macro %,$(libdakota_util_macros))

.PHONY:\
 all\
 check-exes\
 check-libs\
 check\
 clean\
 install\
 installdirs\
 precompile\
 uninstall\

$(blddir)/%.dk: $(blddir)/%.tbl

$(blddir)/%.tbl: $(srcdir)/%.sh
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

check-libs: all
	$(dakota_info_output) $(libdakota_output) $(libdakota_util_output)

check-exes: all
	$(MAKE) --file $@.mk

check: all
	$(MAKE) check-libs
	$(MAKE) check-exes
	./$@.sh

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
	sudo rm -rf $(install_output)

clean:
	$(RM) $(RMFLAGS) $(dakota_info_output){.dSYM,}
	$(RM) $(RMFLAGS) $(libdakota_util_output){.ctlg,}
	$(RM) $(RMFLAGS) $(libdakota_output){.ctlg,}
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler-{darwin,linux}-{clang,gcc}.mk
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler.mk
	$(RM) $(RMFLAGS) $(blddir)/obj
	$(RM) $(RMFLAGS) $(blddir)/sterror-name.tbl
	$(RM) $(RMFLAGS) $(blddir)/{dakota-info,libdakota,libdakota-util}-project.mk
	$(RM) $(RMFLAGS) $(blddir)/{dummy,empty-klass-x,min,tst}
