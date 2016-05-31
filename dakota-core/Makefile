rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

export DKT_EXCLUDE_LIBS = 1

include $(rootdir)/common.mk

include $(shell $(rootdir)/bin/dakota-build2mk --output $(BUILDDIR)/dakota-core.mk $(srcdir)/dakota-core.build)

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

$(srcdir)/strerror-name.dk: $(srcdir)/strerror-name.tbl

single: $(srcs) | dakota-core.project
	for input in $(srcs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) --precompile --compile --define-macro DKT_WORKAROUND --define-macro HAVE_CONFIG_HH --include-directory . --include-directory ../include --project dakota-core.project --output $(builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --precompile --shared --define-macro DKT_WORKAROUND --define-macro HAVE_CONFIG_HH --include-directory . --include-directory ../include --project dakota-core.project
check-exe: all
	echo "func main() -> int-t { klass sorted-table; object-t o = make(sorted-table::klass); USE(o); return 0; }" > exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "target" => "exe" }' > exe.project
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
	if [[ -e dakota-core.project ]]; then $(DAKOTA-BASE) --clean --project dakota-core.project; fi
	$(RM) $(RMFLAGS) dakota-core.project
	$(RM) $(RMFLAGS) exe exe.dk exe.project
	$(RM) $(RMFLAGS) $(srcdir)/strerror-name.tbl
	$(RM) $(RMFLAGS) $(BUILDDIR)

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
	sudo $(RM) $(RMFLAGS) $(install-files)
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/compiler
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(prefix)/lib/dakota/platform.json
	#if [[ -d $(DESTDIR)$(prefix)/lib/dakota ]]; then sudo rmdir $(DESTDIR)$(prefix)/lib/dakota; fi
