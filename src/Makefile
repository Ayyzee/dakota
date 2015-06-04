SHELL := /bin/sh -u

srcdir ?= .
dstdir := .

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

$(shell $(srcdir)/../bin/dakota-json2mk --output $(dstdir)/../lib/dakota/compiler.mk $(srcdir)/../lib/dakota/compiler.json)
include $(dstdir)/../lib/dakota/compiler.mk

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

include $(srcdir)/../config.mk
include $(srcdir)/../vars.mk

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota_      --output $(dstdir)/dakota-project.mk      $(srcdir)/dakota-project.json)
include $(dstdir)/dakota-project.mk

$(shell $(srcdir)/../bin/dakota-json2mk --prefix dakota_util_ --output $(dstdir)/dakota-util-project.mk $(srcdir)/dakota-util-project.json)
include $(dstdir)/dakota-util-project.mk

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

soname =           $(shell $(srcdir)/../bin/dakota-project soname       --repository $*-project.json --var libdir=$(libdir) --var lib_prefix=$(lib_prefix) --var SO_EXT=$(SO_EXT))
macros_raw =       $(shell $(srcdir)/../bin/dakota-project macros       --repository $*-project.json)
include_dirs_raw = $(shell $(srcdir)/../bin/dakota-project include-dirs --repository $*-project.json --var srcdir=$(srcdir))

# soname needs no transformation
macros =       $(patsubst %,--define-macro %,$(macros_raw))            # g++/clang++
include_dirs = $(patsubst %,--include-directory %,$(include_dirs_raw)) # g++/clang++

# the use of $^ should be $?

$(dstdir)/../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared   $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(dstdir)/../lib/%.$(SO_EXT):
	$(DAKOTA) --dynamic  $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --soname $(soname) --output $@ $^ /usr/lib/libdl.$(SO_EXT)

$(dstdir)/../bin/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

$(dstdir)/%:        $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --var MAKEFLAGS="$(MAKEFLAGS)" --output $@ $^

# installed files
$(includedir)/%.$(hh_ext): $(srcdir)/../include/%.$(hh_ext)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0644 $< $(@D)

$(libdir)/$(lib_prefix)%.$(SO_EXT): $(dstdir)/../lib/$(lib_prefix)%.$(SO_EXT)
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.pm: $(srcdir)/../lib/dakota/%.pm
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.pl: $(srcdir)/../lib/dakota/%.pl
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $< $(@D)

$(libdir)/dakota/%.json: $(srcdir)/../lib/dakota/%.json
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

$(dstdir)/../bin/dakota-info: $(srcdir)/dakota-info-main.$(cc_ext)
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

$(dstdir)/tst: $(srcdir)/tst-main.dk $(dstdir)/../lib/$(dakota_util_name)

$(dstdir)/min: $(srcdir)/min-main.dk # $(dstdir)/../lib/$(dakota_name) is implied

$(dstdir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
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

$(dstdir)/strerror-name.dk: $(dstdir)/strerror-name.tbl

$(dstdir)/strerror-name.tbl: $(srcdir)/gen-strerror-name.sh
	./$<

clean: clean-rt
	$(RM) $(RMFLAGS) $(dstdir)/obj $(dstdir)/tst $(dstdir)/dummy $(dstdir)/min $(dstdir)/empty-klass-x
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_name).ctlg
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_util_name).ctlg
	$(RM) $(RMFLAGS) $(dstdir)/../bin/dakota-info
	$(RM) $(RMFLAGS) $(dstdir)/../bin/dakota-info.dSYM
	$(RM) $(RMFLAGS) $(dstdir)/../lib/dakota/compiler.mk $(dstdir)/../lib/dakota/compiler-{darwin,linux}-{clang,gcc}.mk
	$(RM) $(RMFLAGS) $(dstdir)/dakota-project.mk $(srcdir)/dakota-util-project.mk
clean-util-rt:
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_util_name)

clean-rt: clean-util-rt
	$(RM) $(RMFLAGS) $(dstdir)/../lib/$(dakota_name)
