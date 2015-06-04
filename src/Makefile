SHELL := /bin/sh -u

rootdir := ..

$(shell $(rootdir)/bin/dakota-json2mk $(rootdir)/lib/dakota/compiler.pl > compiler.mk)
include compiler.mk

export CXX
export CXXFLAGS

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

$(shell $(rootdir)/bin/dakota-json2mk --prefix dakota_      $(srcdir)/dakota-project.rep      > dakota-project.mk)
$(shell $(rootdir)/bin/dakota-json2mk --prefix dakota_util_ $(srcdir)/dakota-util-project.rep > dakota-util-project.mk)
include dakota-project.mk
include dakota-util-project.mk

INCLUDE_FILES := $(dakota_INCLUDE_FILES)

BIN_FILES := $(dakota_BIN_FILES)

LIB_FILES := $(dakota_LIB_FILES) $(dakota_util_LIB_FILES)

HOME_FILES := $(dakota_HOME_FILES)

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

soname =           $(shell $(rootdir)/bin/dakota-project soname       --repository $*-project.rep --var prefix=$(prefix) --var SO_EXT=$(SO_EXT) --var srcdir=$(srcdir))
macros_raw =       $(shell $(rootdir)/bin/dakota-project macros       --repository $*-project.rep --var prefix=$(prefix) --var SO_EXT=$(SO_EXT) --var srcdir=$(srcdir))
include_dirs_raw = $(shell $(rootdir)/bin/dakota-project include-dirs --repository $*-project.rep --var prefix=$(prefix) --var SO_EXT=$(SO_EXT) --var srcdir=$(srcdir))

# soname needs no transformation
macros =       $(patsubst %,--define-macro %,$(macros_raw))            # g++/clang++
include_dirs = $(patsubst %,--include-directory %,$(include_dirs_raw)) # g++/clang++

# the use of $^ should be $?

$(rootdir)/lib/$(lib_prefix)%.$(SO_EXT):
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/lib/%.$(SO_EXT):
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) --dynamic  $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(rootdir)/bin/%: $(srcdir)/%-main.$(dk_ext)
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^ /usr/lib/libdl.$(SO_EXT)

%: %-main.$(dk_ext)
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

# installed files
$(includedir)/%.$(hxx_ext): $(rootdir)/include/%.$(hxx_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

$(libdir)/$(lib_prefix)%.$(SO_EXT): $(rootdir)/lib/$(lib_prefix)%.$(SO_EXT)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.$(pm_ext): $(rootdir)/lib/dakota/%.$(pm_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.$(pl_ext): $(rootdir)/lib/dakota/%.$(pl_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(bindir)/%: $(rootdir)/bin/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(HOME)/.dakota/%: $(srcdir)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

all:
	$(MAKE) $(rootdir)/bin/dakota-info
	$(MAKE) $(MFLAGS) dakota
	$(MAKE) $(MFLAGS) dakota-util

tst: tst-main.$(dk_ext) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

min: min-main.$(dk_ext)

check: all install
	$(rootdir)/bin/dakota-info $(libdir)/$(lib_prefix)$(dakota_name) $(libdir)/$(lib_prefix)$(dakota_util_name)
	$(MAKE) tst
	./tst
	$(MAKE) dummy
	./dummy

$(rootdir)/lib/$(lib_prefix)$(dakota_util_name): $(dakota_util_srcs)

$(rootdir)/lib/$(lib_prefix)$(dakota_name): $(dakota_srcs)

dakota-util: $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

dakota: $(rootdir)/lib/$(lib_prefix)$(dakota_name)

$(rootdir)/bin/dakota-info: $(srcdir)/dakota-info-main.$(cxx_ext)
	@$(MKDIR) $(MKDIRFLAGS) $(@D)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^ /usr/lib/libdl.$(SO_EXT)

dummy: dummy-main.$(cxx_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

precompile:
	$(MAKE) --always-make --keep-going DAKOTAFLAGS=--$@ all

$(includedir) \
$(bindir) \
$(libdir)/dakota \
$(HOME)/.dakota/emacs:
	sudo $(INSTALL) $(INSTALLFLAGS) -d -m 0755 $@

install-include: $(includedir) $(INCLUDE_FILES)

uninstall-include:
	sudo $(RM) $(RMFLAGS) $(INCLUDE_FILES)

install-bin: $(bindir) $(BIN_FILES)

uninstall-bin:
	sudo $(RM) $(RMFLAGS) $(BIN_FILES)

install-lib: $(libdir)/dakota $(LIB_FILES)

uninstall-lib:
	sudo $(RM) $(RMFLAGS) $(LIB_FILES) $(libdir)/dakota

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
	$(RM) $(RMFLAGS) $(srcdir)/obj tst dummy min empty-klass-x
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-info
	$(RM) $(RMFLAGS) $(rootdir)/bin/dakota-info.dSYM
	$(RM) $(RMFLAGS) compiler.mk strerror-name.tbl .gdb_history *~ .*~ 
	$(MAKE) --directory proofs clean
	$(MAKE) --directory macro-system-parser clean

clean-util-rt:
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(rootdir)/lib/$(lib_prefix)$(dakota_name)
