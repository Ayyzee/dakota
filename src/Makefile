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

include $(blddir)/dakota-info-project.mk
include $(blddir)/libdakota-project.mk
include $(blddir)/libdakota-util-project.mk

# include-dirs
dakota_info_include_dirs :=    $(patsubst %,--include-directory %,$(dakota_info_include_dirs))
libdakota_include_dirs :=      $(patsubst %,--include-directory %,$(libdakota_include_dirs))
libdakota_util_include_dirs := $(patsubst %,--include-directory %,$(libdakota_util_include_dirs))

# macros
dakota_info_macros :=    $(patsubst %,--define-macro %,$(dakota_info_macros))
libdakota_macros :=      $(patsubst %,--define-macro %,$(libdakota_macros))
libdakota_util_macros := $(patsubst %,--define-macro %,$(libdakota_util_macros))

dakota_info_install =    $(dakota_info_install_bins)    $(dakota_info_install_includes)    $(dakota_info_install_libs)
libdakota_install =      $(libdakota_install_bins)      $(libdakota_install_includes)      $(libdakota_install_libs)
libdakota_util_install = $(libdakota_util_install_bins) $(libdakota_util_install_includes) $(libdakota_util_install_libs)

.PHONY:\
 all\
 check-exes\
 check-libs\
 check\
 clean\
 dakota-info\
 install-dakota-info\
 install-libdakota-util\
 install-libdakota\
 install\
 libdakota-util\
 libdakota\
 precompile\
 uninstall-dakota-info\
 uninstall-libdakota-util\
 uninstall-libdakota\
 uninstall\

# precompile-libdakota\
# precompile-libdakota-util\

install_file_mode :=    0644
install_dir_mode :=     0755

install_include_mode := $(install_file_mode)
install_bin_mode :=     0755
install_lib_mode :=     $(install_file_mode)

$(blddir)/%.dk: $(blddir)/%.tbl

$(blddir)/%.tbl: $(srcdir)/%.sh
	./$<

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --soname $(soname) --output $@ $^

### installed files
$(DESTDIR)$(includedir)/%: $(srcdir)/../include/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_include_mode) $< $(@D)

# some lib/* are supplied (so they will be in srcdir)
$(DESTDIR)$(libdir)/%: $(srcdir)/../lib/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

# some lib/* are generated (so they will be in blddir)
$(DESTDIR)$(libdir)/%: $(blddir)/../lib/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

# some lib/dakota/* are supplied (so they will be in srcdir)
$(DESTDIR)$(libdir)/dakota/%: $(srcdir)/../lib/dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

# some lib/dakota/* are generated (so they will be in blddir)
$(DESTDIR)$(libdir)/dakota/%: $(blddir)/../lib/dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

# some bin/* are supplied (so they will be in srcdir)
$(DESTDIR)$(bindir)/%: $(srcdir)/../bin/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_bin_mode) $< $(@D)

# some bin/* are generated (so they will be in blddir)
$(DESTDIR)$(bindir)/%: $(blddir)/../bin/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_bin_mode) $< $(@D)
### installed files

all:
	$(MAKE) dakota-info
	$(MAKE) libdakota libdakota-util

dakota-info:    $(dakota_info_output)
libdakota:      $(libdakota_output)
libdakota-util: $(libdakota_util_output)

$(dakota_info_output): $(dakota_info_srcs) $(dakota_info_libs)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(dakota_info_include_dirs) $(CXX_OUTPUT_FLAGS) $@ $^

$(libdakota_output): $(libdakota_srcs) $(libdakota_libs)
$(libdakota_util_output): $(libdakota_util_srcs) $(libdakota_util_libs)

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

$(bindir) \
$(includedir) \
$(libdir) \
$(libdir)/dakota:
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_CREATE_DIRS_FLAG) $(INSTALL_MODE_FLAG) $(dir_mode) $@

install-dakota-info:    $(dakota_info_install)
install-libdakota:      $(libdakota_install)
install-libdakota-util: $(libdakota_util_install)

uninstall-dakota-info:
	sudo $(RM) $(RMFLAGS) $(strip $(dakota_info_install))
uninstall-libdakota:
	sudo $(RM) $(RMFLAGS) $(strip $(libdakota_install))
uninstall-libdakota-util:
	sudo $(RM) $(RMFLAGS) $(strip $(libdakota_util_install))

install:
	$(MAKE) install-dakota-info
	$(MAKE) install-libdakota
	$(MAKE) install-libdakota-util

uninstall:
	$(MAKE) uninstall-dakota-info
	$(MAKE) uninstall-libdakota
	$(MAKE) uninstall-libdakota-util

clean:
	$(RM) $(RMFLAGS) $(dakota_info_output)
	$(RM) $(RMFLAGS) $(dakota_info_output).dSYM
	$(RM) $(RMFLAGS) $(libdakota_util_output)
	$(RM) $(RMFLAGS) $(libdakota_util_output).ctlg
	$(RM) $(RMFLAGS) $(libdakota_output)
	$(RM) $(RMFLAGS) $(libdakota_output).ctlg
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler-{darwin,linux}-{clang,gcc}.mk
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler.mk
	$(RM) $(RMFLAGS) $(blddir)/obj
	$(RM) $(RMFLAGS) $(blddir)/sterror-name.tbl
	$(RM) $(RMFLAGS) $(blddir)/{dakota-info,libdakota,libdakota-util}-project.mk
	$(RM) $(RMFLAGS) $(blddir)/{dummy,empty-klass-x,min,tst}
