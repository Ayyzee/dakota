SHELL := /bin/sh -u

rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA_ENV_VARS += DK_PREFIX=$(rootdir)

dakota_util_files := $(shell $(rootdir)/bin/dk files --var SO_EXT=$(SO_EXT) --repository dakota-util.rep)
dakota_files :=      $(shell $(rootdir)/bin/dk files --var SO_EXT=$(SO_EXT) --repository dakota.rep)

dakota_util_name := $(shell $(rootdir)/bin/dk name --var SO_EXT=$(SO_EXT) --repository dakota-util.rep)
dakota_name :=      $(shell $(rootdir)/bin/dk name --var SO_EXT=$(SO_EXT) --repository dakota.rep)

INCLUDE_FILES :=\
 $(DESTDIR)$(includedir)/dakota-log.$(hxx_ext)\
 $(DESTDIR)$(includedir)/dakota.$(hxx_ext)\

BIN_FILES :=\
 $(DESTDIR)$(bindir)/dakota-introspector$(exeext)\
 $(DESTDIR)$(bindir)/dakota$(exeext)\
 $(DESTDIR)$(bindir)/dk-fixup-stderr.$(pl_ext)\
 $(DESTDIR)$(bindir)/dk-rootdir.$(pl_ext)\
 $(DESTDIR)$(bindir)/dk\

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
 tst\

# the use of $^ should be $?

$(rootdir)/lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/lib/%.$(SO_EXT):
	$(DAKOTA) --dynamic --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/bin/%$(exeext): $(srcdir)/%-main.$(dk_ext)
	$(DAKOTA) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

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

$(HOME)/.dakota/%: $(srcdir)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

all:
	$(MAKE) $(rootdir)/bin/dakota-introspector$(exeext)
	$(MAKE) $(MFLAGS) dakota
	$(MAKE) $(MFLAGS) dakota-util

tst: tst-main.$(dk_ext)
	CXXFLAGS="${CXXFLAGS} --debug=3" $(DAKOTA) --output $@ $^ $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

check: all install
	$(rootdir)/bin/dakota-introspector$(exeext) $(libdir)/$(lib_prefix)$(dakota_name) $(libdir)/$(lib_prefix)$(dakota_util_name)
	$(MAKE) tst
	./tst

$(rootdir)/lib/$(lib_prefix)$(dakota_util_name): $(dakota_util_files)

$(rootdir)/lib/$(lib_prefix)$(dakota_name): $(dakota_files)

dakota-util: $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

dakota: $(rootdir)/lib/$(lib_prefix)$(dakota_name)

$(rootdir)/bin/dakota-introspector$(exeext): $(srcdir)/dakota-introspector-main.$(cxx_ext)
	@$(MKDIR) $(MKDIRFLAGS) $(@D)
	$(CXX) $(EXTRA_CXXFLAGS) $(CXXFLAGS) $(CXX_OUTPUT_FLAG) $@ $^ /usr/lib/libdl.$(SO_EXT)

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

sys-err-names.$(dk_ext): sys-err-names.tbl

sys-err-names.tbl: gen-sys-err-names.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(srcdir)/obj tst
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-introspector$(exeext)
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-introspector$(exeext).dSYM
	$(RM) $(RMFLAGS) sys-err-names.tbl .gdb_history *~ .*~ 
	$(MAKE) --directory proofs clean
	$(MAKE) --directory macro-system clean

clean-util-rt:
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name)
