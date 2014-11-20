rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/common.mk

EXTRA_CXXFLAGS +=\
 -std=c++11\
 --include-directory=$(srcdir)/.\
 --include-directory=../include\
 --include-directory=$(includedir)\

ifndef MIN_EXTRA_CXXFLAGS
 # optional
EXTRA_CXXFLAGS += --define-macro DEBUG
#EXTRA_CXXFLAGS += --define-macro DUMP_MEM_FOOTPRINT
#EXTRA_CXXFLAGS += --define-macro DK_USE_MAKE_MACRO

 EXTRA_CXXFLAGS +=\
 --define-macro HAVE_CONFIG_H\
 -fno-common\
 -ftrapv\
 --debug=3\
 --optimize=0\
 -Wno-multichar\
 -Wno-four-char-constants\
 --all-warnings\
 --warn-cast-qual\
 --warn-extra\
 --warn-format=2\
 --warn-missing-format-attribute\
 --warn-missing-include-dirs\
 --warn-no-variadic-macros\
 --warn-pointer-arith\
 --warn-shadow\
 --warn-switch-enum\
 --warn-undef\
 --warn-unused\
 --warn-no-multichar\
 --warn-conversion\
 -std=c++11\
 -DMOD_SIZE_CAST_HACK\

 # --warn-redundant-decls
 # --warn-switch-default
 # --no-warnings


#if SO_EXT eq "dylib"

#EXTRA_CXXFLAGS_DARWIN_64 := -arch x86_64 -mmacosx-version-min=10.5 -Wshorten-64-to-32

#EXTRA_CXXFLAGS += $(EXTRA_CXXFLAGS_DARWIN_64)

#EXTRA_LDFLAGS_DARWIN_64 += -arch x86_64

#EXTRA_LDFLAGS += $(EXTRA_LDFLAGS_DARWIN_64)

#endif


endif

ifndef DK_USE_COMPOUND_LITERALS
  EXTRA_CXXFLAGS += --pedantic
endif

ifdef DK_PROFILE
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS +=  -pg
endif

DK_PREFIX ?= ..

DAKOTA_ENV_VARS += DK_PREFIX=$(DK_PREFIX)

CXX ?= g++
DAKOTA_ENV_VARS += CXX=$(CXX)

SO_EXT ?= so
DAKOTA_ENV_VARS += SO_EXT=$(SO_EXT)

DAKOTA ?= $(DAKOTA_ENV_VARS) $(DK_PREFIX)/bin/dakota
#DAKOTA ?= $(DAKOTA_ENV_VARS) $(DK_PREFIX)/bin/dakota-profile

CXXFLAGS ?=
DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS ?=

export CXX
export EXTRA_CXXFLAGS
#export LD
export EXTRA_LDFLAGS
export DAKOTA
export EXTRA_DAKOTAFLAGS

dakota_util_files := $(shell $(DK_PREFIX)/bin/dk files --var SO_EXT=$(SO_EXT) --repository dakota-util.rep)
dakota_files :=      $(shell $(DK_PREFIX)/bin/dk files --var SO_EXT=$(SO_EXT) --repository dakota.rep)

dakota_util_name := $(shell $(DK_PREFIX)/bin/dk name --var SO_EXT=$(SO_EXT) --repository dakota-util.rep)
dakota_name :=      $(shell $(DK_PREFIX)/bin/dk name --var SO_EXT=$(SO_EXT) --repository dakota.rep)

INCLUDE_FILES :=\
 $(DESTDIR)$(includedir)/dakota-before-klasses.$(hxx_ext)\
 $(DESTDIR)$(includedir)/dakota-before-rt-code.$(hxx_ext)\
 $(DESTDIR)$(includedir)/dakota-before-user-code.$(hxx_ext)\
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
 $(DESTDIR)$(libdir)/dakota.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_include.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_parse.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_rewrite.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_generate.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_sst.$(pm_ext)\
 $(DESTDIR)$(libdir)/dakota_util.$(pm_ext)\

HOME_FILES :=\
 $(HOME)/.dakota/.gdbinit\
 $(HOME)/.dakota/.bashrc\
 $(HOME)/.dakota/.emacs\
 $(HOME)/.dakota/dakota-mode.el\

.PHONY:\
 all\
 check\
 precompile\
 install-include\
 install-bin\
 install-lib\
 install\
 uninstall-include\
 uninstall-bin\
 uninstall-lib\
 uninstall\
 clean\
 tst\

# the use of $^ should be $?

$(DK_PREFIX)/lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^ /usr/lib/libdl.$(SO_EXT)

$(DK_PREFIX)/lib/%.$(SO_EXT):
	$(DAKOTA) --dynamic --output $@ --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^ /usr/lib/libdl.$(SO_EXT)

$(DK_PREFIX)/bin/%$(exeext): $(srcdir)/%-main.$(dk_ext)
	$(DAKOTA) --output $@ $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^ /usr/lib/libdl.$(SO_EXT)

# installed files
$(DESTDIR)$(includedir)/%.$(hxx_ext): $(DK_PREFIX)/include/%.$(hxx_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

$(DESTDIR)$(libdir)/$(lib_prefix)%.$(SO_EXT): $(DK_PREFIX)/lib/$(lib_prefix)%.$(SO_EXT)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(DESTDIR)$(libdir)/%.$(pm_ext): $(DK_PREFIX)/lib/%.$(pm_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(DESTDIR)$(bindir)/%$(exeext): $(DK_PREFIX)/bin/%$(exeext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(HOME)/.dakota/%: $(srcdir)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

all:
	$(MAKE) $(MFLAGS) $(DK_PREFIX)/bin/dakota-introspector$(exeext)
	$(MAKE) $(MFLAGS) dakota
	$(MAKE) $(MFLAGS) dakota-util

tst: tst-main.$(dk_ext)
	CXXFLAGS="--debug=3" $(DAKOTA) $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_util_name) --output $@ $^

check: all install
	$(DK_PREFIX)/bin/dakota-introspector$(exeext) $(libdir)/$(lib_prefix)$(dakota_name) $(libdir)/$(lib_prefix)$(dakota_util_name)
	$(MAKE) tst
	./tst

$(DK_PREFIX)/lib/$(lib_prefix)$(dakota_util_name): $(dakota_util_files)

$(DK_PREFIX)/lib/$(lib_prefix)$(dakota_name): $(dakota_files)

dakota-util: $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_util_name)

dakota: $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_name)

$(DK_PREFIX)/bin/dakota-introspector$(exeext): $(srcdir)/dakota-introspector-main.$(cxx_ext)
	@$(MKDIR) $(MKDIRFLAGS) $(@D)
	$(CXX) $(CXX_OUTPUT_FLAG) $@ $(EXTRA_CXXFLAGS) $(CXXFLAGS) $^ /usr/lib/libdl.$(SO_EXT)

precompile:
	@$(MAKE) $(MFLAGS) --always-make DAKOTAFLAGS=--$@ all

$(DESTDIR)$(includedir) \
$(DESTDIR)$(bindir) \
$(DESTDIR)$(libdir) \
$(HOME)/.dakota:
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 -d $@

install-include: $(DESTDIR)$(includedir) $(INCLUDE_FILES)

uninstall-include:
	sudo $(RM) $(RMFLAGS) $(INCLUDE_FILES)

install-bin: $(DESTDIR)$(bindir) $(BIN_FILES)

uninstall-bin:
	sudo $(RM) $(RMFLAGS) $(BIN_FILES)

install-lib: $(DESTDIR)$(libdir) $(LIB_FILES)

uninstall-lib:
	sudo $(RM) $(RMFLAGS) $(LIB_FILES)

install-home: $(HOME)/.dakota $(HOME_FILES)

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
	svn $@

rt: clean-rt
	$(MAKE) $(MFLAGS) all

sys-err-names.$(dk_ext): sys-err-names.tbl

sys-err-names.tbl: gen-sys-err-names.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(srcdir)/obj tst
	$(RM) $(RMFLAGS) $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_util_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(DK_PREFIX)/bin/dakota-introspector$(exeext)
	$(RM) $(RMFLAGS) $(DK_PREFIX)/bin/dakota-introspector$(exeext).dSYM
	$(RM) $(RMFLAGS) sys-err-names.tbl .gdb_history *~ .*~ 
	$(MAKE) --directory proofs clean
	$(MAKE) --directory macro-system clean

clean-util-rt:
	$(RM) $(RMFLAGS) $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(DK_PREFIX)/lib/$(lib_prefix)$(dakota_name)
