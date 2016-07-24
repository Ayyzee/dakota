rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

export DKT_EXCLUDE_LIBS = 1

builddir := $(shell $(rootdir)/bin/dakota-build builddir build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/build.mk build)

# include-dirs
include-dirs := $(patsubst %,--include-directory %,$(include-dirs))

# macros
macros := $(patsubst %,--define-macro %,$(macros))

.PRECIOUS: %.project project

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

single: $(srcs) | project
	for input in $(srcs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) --include-directory $(srcdir) --include-directory $(srcdir)/../include --compile --output $(builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --include-directory $(srcdir) --include-directory $(srcdir)/../include --shared

check-exe: all
	echo "klass sorted-table; func main() -> int-t { object-t o = make(sorted-table::klass); USE(o); return 0; }" > exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "builddir" => "dkt-exe" }' > exe.project
	rm -f exe
	DKT_EXCLUDE_LIBS=2 $(DAKOTA-BASE) --project exe.project exe.dk
	./exe

check: all
	dakota-catalog --silent $(target)
	$(MAKE) $(MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target-files)

clean: goal-clean
	$(MAKE) $(MAKEFLAGS) --silent project
	$(DAKOTA-BASE) --clean
	$(RM) $(RMFLAGS) project
	$(RM) $(RMFLAGS) exe exe.dk exe.project
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dkt-exe
	$(RM) $(RMFLAGS) $(srcdir)/strerror-name.tbl

$(srcdir)/strerror-name.dk: $(srcdir)/strerror-name.tbl

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(prefix)/{bin,include,lib/dakota/compiler-$(compiler)}

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
