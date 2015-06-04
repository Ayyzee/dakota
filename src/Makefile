SHELL := /bin/sh -u

srcdir ?= .
dstdir := .

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

json_ext := json
mk_ext := mk

$(shell $(srcdir)/../bin/dakota-json2mk --output $(dstdir)/../lib/dakota/compiler.$(mk_ext) $(srcdir)/../lib/dakota/compiler.$(json_ext))
include $(dstdir)/../lib/dakota/compiler.$(mk_ext)

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

include $(srcdir)/../config.$(mk_ext)
include $(srcdir)/../vars.$(mk_ext)

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota_      --output $(dstdir)/dakota-project.$(mk_ext)      $(srcdir)/dakota-project.$(json_ext))
include $(dstdir)/dakota-project.$(mk_ext)

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota_util_ --output $(dstdir)/dakota-util-project.$(mk_ext) $(srcdir)/dakota-util-project.$(json_ext))
include $(dstdir)/dakota-util-project.$(mk_ext)

INCLUDE_FILES := $(dakota_INCLUDE_FILES)

BIN_FILES := $(dakota_BIN_FILES)

LIB_FILES := $(dakota_LIB_FILES) $(dakota_util_LIB_FILES)

HOME_FILES := $(dakota_HOME_FILES)

.PHONY:\
 all\
 dakota-info\
 dakota\
 dakota-util\
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

soname =           $(shell $(srcdir)/../bin/dakota-project soname       --repository $*-project.$(json_ext) --var libdir=$(libdir) --var lib_prefix=$(lib_prefix) --var SO_EXT=$(SO_EXT))
macros_raw =       $(shell $(srcdir)/../bin/dakota-project macros       --repository $*-project.$(json_ext))
include_dirs_raw = $(shell $(srcdir)/../bin/dakota-project include-dirs --repository $*-project.$(json_ext) --var srcdir=$(srcdir))

# soname needs no transformation
macros =       $(patsubst %,--define-macro %,$(macros_raw))            # g++/clang++
include_dirs = $(patsubst %,--include-directory %,$(include_dirs_raw)) # g++/clang++

# the use of $^ should be $?

$(dstdir)/../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared   $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(dstdir)/../lib/%.$(SO_EXT):
	$(DAKOTA) --dynamic  $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(dstdir)/../bin/%: $(srcdir)/%-main.$(dk_ext)
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

$(dstdir)/%:        $(srcdir)/%-main.$(dk_ext)
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

# installed files
$(includedir)/%.$(hxx_ext): $(srcdir)/../include/%.$(hxx_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

$(libdir)/$(lib_prefix)%.$(SO_EXT): $(dstdir)/../lib/$(lib_prefix)%.$(SO_EXT)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.$(pm_ext): $(srcdir)/../lib/dakota/%.$(pm_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.$(pl_ext): $(srcdir)/../lib/dakota/%.$(pl_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.$(json_ext): $(srcdir)/../lib/dakota/%.$(json_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(bindir)/%: $(srcdir)/../bin/% # some bin/* are supplied (so they will be in srcdir)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(bindir)/%: $(dstdir)/../bin/% # some bin/* are generated (so they will be in dstdir)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(HOME)/.dakota/%: $(srcdir)/home/.dakota/%
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

all:
	$(MAKE) $(MFLAGS) dakota-info
	$(MAKE) $(MFLAGS) dakota
	$(MAKE) $(MFLAGS) dakota-util

dakota-info: $(dstdir)/../bin/dakota-info
dakota:      $(dstdir)/../lib/$(dakota_name)
dakota-util: $(dstdir)/../lib/$(dakota_util_name)

$(dstdir)/../bin/dakota-info: $(srcdir)/dakota-info-main.$(cxx_ext)
	@$(MKDIR) $(MKDIRFLAGS) $(@D)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^ /usr/lib/libdl.$(SO_EXT)

$(dstdir)/../lib/$(dakota_name): $(dakota_srcs)

$(dstdir)/../lib/$(dakota_util_name): $(dakota_util_srcs)

check: all
	$(dstdir)/../bin/dakota-info $(dstdir)/../lib/$(dakota_name) $(dstdir)/../lib/$(dakota_util_name)
	$(MAKE) $(dstdir)/tst
	$(dstdir)/tst
	$(MAKE) $(dstdir)/min
	$(dstdir)/min
	$(MAKE) $(dstdir)/dummy
	$(dstdir)/dummy

$(dstdir)/tst: $(srcdir)/tst-main.$(dk_ext) $(dstdir)/../lib/$(dakota_util_name)

$(dstdir)/min: $(srcdir)/min-main.$(dk_ext) # $(dstdir)/../lib/$(dakota_name) is implied

$(dstdir)/dummy: $(srcdir)/dummy-main.$(cxx_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

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

$(dstdir)/strerror-name.$(dk_ext): $(dstdir)/strerror-name.tbl

$(dstdir)/strerror-name.tbl: $(srcdir)/gen-strerror-name.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(dstdir)/obj $(dstdir)/tst $(dstdir)/dummy $(dstdir)/min $(dstdir)/empty-klass-x
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_util_name).$(ctlg_ext)
	$(RM) $(RMFLAGS) $(dstdir)/../bin/dakota-info
	$(RM) $(RMFLAGS) $(dstdir)/../bin/dakota-info.dSYM
	$(RM) $(RMFLAGS) $(dstdir)/../lib/dakota/compiler.$(mk_ext) $(dstdir)/../lib/dakota/compiler-{darwin,linux}-{clang,gcc}.$(mk_ext)
	$(RM) $(RMFLAGS) $(dstdir)/dakota-project.$(mk_ext) $(srcdir)/dakota-util-project.$(mk_ext)
clean-util-rt:
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_name)
