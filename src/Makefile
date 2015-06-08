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

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota-info --output $(blddir)/dakota-info-project.mk $(srcdir)/dakota-info-project.rep)
$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota      --output $(blddir)/dakota-project.mk      $(srcdir)/dakota-project.rep)
$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota-util --output $(blddir)/dakota-util-project.mk $(srcdir)/dakota-util-project.rep)

include $(blddir)/dakota-info-project.mk
include $(blddir)/dakota-project.mk
include $(blddir)/dakota-util-project.mk

# include-dirs
dakota_info_include_dirs := $(patsubst %,--include-directory %,$(dakota_info_include_dirs))
dakota_include_dirs :=      $(patsubst %,--include-directory %,$(dakota_include_dirs))
dakota_util_include_dirs := $(patsubst %,--include-directory %,$(dakota_util_include_dirs))

# macros
dakota_info_macros := $(patsubst %,--define-macro %,$(dakota_info_macros))
dakota_macros :=      $(patsubst %,--define-macro %,$(dakota_macros))
dakota_util_macros := $(patsubst %,--define-macro %,$(dakota_util_macros))

dakota_info_install = $(dakota_info_install_bins) $(dakota_info_install_includes) $(dakota_info_install_libs)
dakota_install =      $(dakota_install_bins)      $(dakota_install_includes)      $(dakota_install_libs)
dakota_util_install = $(dakota_util_install_bins) $(dakota_util_install_includes) $(dakota_util_install_libs)

.PHONY:\
 all\
 dakota-info\
 dakota\
 dakota-util\
 check\
 clean\
 install-dakota-info\
 install-dakota\
 install-dakota-util\
 install\
 precompile\
 uninstall-dakota-info\
 uninstall-dakota\
 uninstall-dakota-util\
 uninstall\

# precompile-dakota\
# precompile-dakota-util\

$(blddir)/../bin/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

$(blddir)/%:        $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

install_file_mode :=    0644
install_dir_mode :=     0755

install_include_mode := $(install_file_mode)
install_bin_mode :=     0755
install_lib_mode :=     $(install_file_mode)

# installed files
$(DESTDIR)$(includedir)/%: $(srcdir)/../include/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_include_mode) $< $(@D)

$(DESTDIR)$(libdir)/%: $(blddir)/../lib/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

$(DESTDIR)$(libdir)/dakota/%: $(srcdir)/../lib/dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_lib_mode) $< $(@D)

# some bin/* are supplied (so they will be in srcdir)
$(DESTDIR)$(bindir)/%: $(srcdir)/../bin/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_bin_mode) $< $(@D)

# some bin/* are generated (so they will be in blddir)
$(DESTDIR)$(bindir)/%: $(blddir)/../bin/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_bin_mode) $< $(@D)

$(HOME)/.dakota/%: $(srcdir)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_MODE_FLAG) $(install_file_mode) $< $(@D)

all:
	$(MAKE) dakota-info
	$(MAKE) dakota
	$(MAKE) dakota-util

dakota-info: $(blddir)/../bin/dakota-info
dakota:      $(blddir)/../lib/$(lib_prefix)dakota.$(so_ext)
dakota-util: $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)

$(blddir)/../bin/dakota-info: $(dakota_info_srcs) $(dakota_info_libs)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

$(blddir)/../lib/$(lib_prefix)dakota.$(so_ext): $(dakota_srcs) $(dakota_libs)
	$(DAKOTA) --shared  $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(dakota_macros) $(dakota_include_dirs) --soname $(dakota_soname) --output $@ $^

$(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext): $(dakota_util_srcs) $(dakota_util_libs)
	$(DAKOTA) --shared  $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(dakota_util_macros) $(dakota_util_include_dirs) --soname $(dakota_util_soname) --output $@ $^

check: all
	$(blddir)/../bin/dakota-info $(blddir)/../lib/$(lib_prefix)dakota.$(so_ext) $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)
	$(MAKE) $(blddir)/tst
	$(blddir)/tst
	$(MAKE) $(blddir)/min
	$(blddir)/min
	$(MAKE) $(blddir)/dummy
	$(blddir)/dummy

$(blddir)/tst: $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

precompile:
	$(MAKE) --always-make --keep-going DAKOTAFLAGS=--$@ all

$(includedir) \
$(bindir) \
$(libdir)/dakota \
$(HOME)/.dakota/emacs:
	sudo $(INSTALL) $(INSTALLFLAGS) $(INSTALL_CREATE_DIRS_FLAG) $(INSTALL_MODE_FLAG) $(dir_mode) $@

install-dakota-info: $(dakota_info_install)
install-dakota:      $(dakota_install)
install-dakota-util: $(dakota_util_install)

uninstall-dakota-info:
	sudo $(RM) $(RMFLAGS) $(dakota_info_install)
uninstall-dakota:
	sudo $(RM) $(RMFLAGS) $(dakota_install)
uninstall-dakota-util:
	sudo $(RM) $(RMFLAGS) $(dakota_util_install)

install-dakota-home: $(HOME)/.dakota/emacs $(dakota_install_home)

uninstall-dakota-home:
	sudo $(RM) $(RMFLAGS) $(dakota_install_home)

install:\
 install-dakota-info\
 install-dakota\
 install-dakota-util\
 install-home\

uninstall:\
 uninstall-dakota-info\
 uninstall-dakota\
 uninstall-dakota-util\
 uninstall-home\

diff:
	git $@

rt: clean-rt
	$(MAKE) all

$(blddir)/%.dk: $(blddir)/%.tbl

$(blddir)/%.tbl: $(srcdir)/%.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(blddir)/../bin/dakota-info
	$(RM) $(RMFLAGS) $(blddir)/../bin/dakota-info.dSYM
	$(RM) $(RMFLAGS) $(blddir)/../lib/$(lib_prefix)dakota.$(so_ext).ctlg
	$(RM) $(RMFLAGS) $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext).ctlg
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler-{darwin,linux}-{clang,gcc}.mk
	$(RM) $(RMFLAGS) $(blddir)/../lib/dakota/compiler.mk
	$(RM) $(RMFLAGS) $(blddir)/obj
	$(RM) $(RMFLAGS) $(blddir)/sterror-name.tbl
	$(RM) $(RMFLAGS) $(blddir)/{dakota-info,dakota,dakota-util}-project.mk
	$(RM) $(RMFLAGS) $(blddir)/{dummy,empty-klass-x,min,tst}

clean-util-rt:
	$(RM) $(RMFLAGS) $(blddir)/../lib/$(lib_prefix)dakota-util.$(so_ext)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(blddir)/../lib/$(lib_prefix)dakota.$(so_ext)
