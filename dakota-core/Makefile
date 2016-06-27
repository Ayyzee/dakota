rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

export DKT_EXCLUDE_LIBS = 1

target-base := dakota-core
builddir := $(shell $(rootdir)/bin/dakota-build builddir $(target-base).build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/$(target-base).mk $(target-base).build)

# include-dirs
include-dirs := $(patsubst %,--include-directory %,$(include-dirs))

# macros
macros := $(patsubst %,--define-macro %,$(macros))

# should be generated
install-dirs := $(DESTDIR)$(prefix)/bin $(DESTDIR)$(prefix)/include $(DESTDIR)$(prefix)/lib/dakota

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

single: $(srcs) | $(target-base).project
	for input in $(srcs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) --compile --include-directory . --include-directory ../include --project $(target-base).project --output $(builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --shared --include-directory . --include-directory ../include --project $(target-base).project

check-exe: all
	echo "klass sorted-table; func main() -> int-t { object-t o = make(sorted-table::klass); USE(o); return 0; }" > exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "builddir" => "dkt-exe" }' > exe.project
	rm -f exe
	DKT_EXCLUDE_LIBS=2 $(DAKOTA-BASE) exe.dk
	./exe

check: all
	../bin/dakota-catalog --silent $(target)
	$(MAKE) $(MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target-files)

clean: goal-clean
	if [[ -e $(target-base).project ]]; then $(DAKOTA-BASE) --clean --project $(target-base).project; fi
	$(RM) $(RMFLAGS) $(target-base).project
	$(RM) $(RMFLAGS) exe exe.dk exe.project
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dkt-exe
	$(RM) $(RMFLAGS) $(srcdir)/strerror-name.tbl

$(srcdir)/strerror-name.dk: $(srcdir)/strerror-name.tbl

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(prefix)/{bin,include,lib/dakota/compiler-{clang,gcc}}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

$(DESTDIR)$(prefix)/lib/dakota/platform.json: $(DESTDIR)$(prefix)/lib/dakota/platform-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(prefix)/lib/dakota/compiler: $(DESTDIR)$(prefix)/lib/dakota/compiler-$(compiler)
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

install-links := $(DESTDIR)$(prefix)/lib/dakota/compiler $(DESTDIR)$(prefix)/lib/dakota/platform.json

install: all $(install-dirs) $(install-files) $(install-links)

precompile:
	$(MAKE) $(MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install-files) $(install-links)
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/compiler
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/platform.json
