SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA_VARS += DK_PREFIX=$(rootdir)

dakota_util_files := $(shell $(rootdir)/bin/dakota-project files --repository dakota-util-project.rep --var SO_EXT=$(SO_EXT))
dakota_files :=      $(shell $(rootdir)/bin/dakota-project files --repository dakota-project.rep      --var SO_EXT=$(SO_EXT))

dakota_util_name := $(shell $(rootdir)/bin/dakota-project name --repository dakota-util-project.rep --var SO_EXT=$(SO_EXT))
dakota_name :=      $(shell $(rootdir)/bin/dakota-project name --repository dakota-project.rep      --var SO_EXT=$(SO_EXT))

INCLUDE_FILES :=\
 $(DESTDIR)$(includedir)/dakota-log.$(hxx_ext)\
 $(DESTDIR)$(includedir)/dakota-finally.$(hxx_ext)\
 $(DESTDIR)$(includedir)/dakota.$(hxx_ext)\

BIN_FILES :=\
 $(DESTDIR)$(bindir)/dakota-info$(exeext)\
 $(DESTDIR)$(bindir)/dakota$(exeext)\
 $(DESTDIR)$(bindir)/dakota-fixup-stderr.$(pl_ext)\
 $(DESTDIR)$(bindir)/dakota-rootdir.$(pl_ext)\
 $(DESTDIR)$(bindir)/dakota-project$(exeext)\

LIB_FILES :=\
 $(DESTDIR)$(libdir)/$(lib_prefix)$(dakota_name)\
 $(DESTDIR)$(libdir)/$(lib_prefix)$(dakota_util_name)\
 $(DESTDIR)$(libdir)/dakota/dakota.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/parse.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/rewrite.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/generate.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/sst.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/util.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota/macros.$(pl_ext)\

HOME_FILES :=\
 $(HOME)/.dakota/.gdbinit\
 $(HOME)/.dakota/.bashrc\
 $(HOME)/.dakota/emacs/init.el\
 $(HOME)/.dakota/emacs/dakota-mode.el\

.PHONY:\
 all\
 check\
 clean\
 install-include\
 install-bin\
 install-lib\
 install\
 precompile\
 uninstall-include\
 uninstall-bin\
 uninstall-lib\
 uninstall\

soname = $(shell $(rootdir)/bin/dakota-project soname --repository $*-project.rep --var prefix=$(prefix) --var SO_EXT=$(SO_EXT))

# the use of $^ should be $?

$(rootdir)/lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared $(INCLUDE_DAKOTAFLAGS) $(DAKOTAFLAGS) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/lib/%.$(SO_EXT):
	$(DAKOTA) --dynamic  $(INCLUDE_DAKOTAFLAGS) $(DAKOTAFLAGS) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/bin/%$(exeext): $(SRCDIR)/%-main.$(dk_ext)
	$(DAKOTA) $(INCLUDE_DAKOTAFLAGS) $(DAKOTAFLAGS) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^ /usr/lib/libdl.$(SO_EXT)

%: %-main.$(dk_ext)
	CXXFLAGS="$(CXXFLAGS)" EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(INCLUDE_DAKOTAFLAGS) $(DAKOTAFLAGS) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

# installed files
$(DESTDIR)$(includedir)/%.$(hxx_ext): $(rootdir)/include/%.$(hxx_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

$(DESTDIR)$(libdir)/$(lib_prefix)%.$(SO_EXT): $(rootdir)/lib/$(lib_prefix)%.$(SO_EXT)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(DESTDIR)$(libdir)/dakota/%.$(pm_ext): $(rootdir)/lib/dakota/%.$(pm_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(DESTDIR)$(libdir)/dakota/%.$(pl_ext): $(rootdir)/lib/dakota/%.$(pl_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(DESTDIR)$(bindir)/%$(exeext): $(rootdir)/bin/%$(exeext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(HOME)/.dakota/%: $(SRCDIR)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

all:
	$(MAKE) $(rootdir)/bin/dakota-info$(exeext)
	$(MAKE) $(MFLAGS) dakota
	$(MAKE) $(MFLAGS) dakota-util

tst: tst-main.$(dk_ext) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

min: min-main.$(dk_ext)

dummy: dummy-main.$(cxx_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_OUTPUT_FLAG) $@ $^

check: all install
	$(rootdir)/bin/dakota-info$(exeext) $(libdir)/$(lib_prefix)$(dakota_name) $(libdir)/$(lib_prefix)$(dakota_util_name)
	$(MAKE) tst
	./tst
	$(MAKE) dummy
	./dummy

check-headers:
	$(CXX) $(CXXFLAGS) $(CXX_COMPILE_FLAGS) $(CXX_NO_WARNINGS_FLAGS) $(INCLUDE_DAKOTAFLAGS) dakota-private.hh

$(rootdir)/lib/$(lib_prefix)$(dakota_util_name): $(dakota_util_files)

$(rootdir)/lib/$(lib_prefix)$(dakota_name): $(dakota_files)

dakota-util: $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

dakota: $(rootdir)/lib/$(lib_prefix)$(dakota_name)

# INCLUDE_DAKOTAFLAGS is a dakota variable, not a g++/clang++ variable, but they share the same syntax
$(rootdir)/bin/dakota-info$(exeext): $(SRCDIR)/dakota-info-main.$(cxx_ext)
	@$(MKDIR) $(MKDIRFLAGS) $(@D)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(INCLUDE_DAKOTAFLAGS) $(CXX_OUTPUT_FLAG) $@ $^ /usr/lib/libdl.$(SO_EXT)

precompile:
	$(MAKE) --always-make --keep-going DAKOTAFLAGS=--$@ all

$(DESTDIR)$(includedir) \
$(DESTDIR)$(bindir) \
$(DESTDIR)$(libdir)/dakota \
$(HOME)/.dakota/emacs:
	sudo $(INSTALL) $(INSTALLFLAGS) -d -m 0755 $@

install-include: $(DESTDIR)$(includedir) $(INCLUDE_FILES)

uninstall-include:
	sudo $(RM) $(RMFLAGS) $(INCLUDE_FILES)

install-bin: $(DESTDIR)$(bindir) $(BIN_FILES)

uninstall-bin:
	sudo $(RM) $(RMFLAGS) $(BIN_FILES)

install-lib: $(DESTDIR)$(libdir)/dakota $(LIB_FILES)

uninstall-lib:
	sudo $(RM) $(RMFLAGS) $(LIB_FILES) $(DESTDIR)$(libdir)/dakota

install-home: $(HOME)/.dakota/emacs $(HOME_FILES)

uninstall-home:
	sudo $(RM) $(RMFLAGS) $(HOME_FILES)

install:\
 install-include\
 install-bin\
 install-lib\
 install-home\

uninstall:\
 uninstall-include\
 uninstall-bin\
 uninstall-lib\
 uninstall-home\

diff:
	git $@

rt: clean-rt
	$(MAKE) all

strerror-name.$(dk_ext): strerror-name.tbl

strerror-name.tbl: gen-strerror-name.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(SRCDIR)/obj tst dummy min
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-info$(exeext)
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-info$(exeext).dSYM
	$(RM) $(RMFLAGS) strerror-name.tbl .gdb_history *~ .*~ 
	$(MAKE) --directory proofs clean
	$(MAKE) --directory macro-system clean

clean-util-rt:
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name)
