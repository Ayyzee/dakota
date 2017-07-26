rootdir := ..

SOURCE_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output dk-vars.mk dakota.build)
target := lib$(target).$(so_ext)

.PRECIOUS: %.project

.PHONY:\
 all\
 check\
 check-exe\
 clean\
 distclean\
 goal-clean\
 install\
 installcheck\
 precompile\
 single\
 uninstall\

all: $(target)

$(target): $(srcs)

single: $(srcs) | dakota.project
	for input in $(srcs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) $(macros:%=--define-macro %) $(include-dirs:%=--include-directory %) --compile --output $(builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --shared

check-exe: all
	echo "# include \"test.h\"" > exe.dk
	echo "klass sorted-table; func main() -> int-t { object-t o = \$$make(sorted-table::klass()); USE(o); EXIT(0); }" >> exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "lib-dirs" => [ "\$${INSTALL_PREFIX}/lib" ], "builddir" => "build-dkt-exe" }' > exe.project
	rm -f exe
	$(DAKOTA) --project exe.project
	./exe

check: all
	dakota-catalog --silent $(target) > $(target).ctlg
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target)

distclean: clean
	cd $(rootdir); ./configure-common

precompile:
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files) $(install-links)

install-dirs :=  $(INSTALL_PREFIX)/bin $(INSTALL_PREFIX)/include $(INSTALL_PREFIX)/lib/dakota
install-links := $(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json $(INSTALL_PREFIX)/lib/dakota/platform.json

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install.files) $(install-links)

clean: goal-clean | dakota.project
	$(DAKOTA-BASE) --project dakota.project --clean
	$(RM) $(RMFLAGS) exe exe.dk exe.project dakota.project
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dk-compiler.mk dk-vars.mk
	$(RM) $(RMFLAGS) build-dkt-exe
	$(RM) $(RMFLAGS) $(target).ctlg
	$(RM) $(RMFLAGS) $(SOURCE_DIR)/strerror-name-tbl.inc

$(SOURCE_DIR)/strerror-name.dk: $(SOURCE_DIR)/strerror-name-tbl.inc

$(INSTALL_PREFIX)/lib/dakota/platform.json:              $(INSTALL_PREFIX)/lib/dakota/platform-$(platform).json
$(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json: $(INSTALL_PREFIX)/lib/dakota/compiler-command-line-$(compiler).json
