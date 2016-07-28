rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

export DKT_EXCLUDE_LIBS = 2

builddir := $(shell $(rootdir)/bin/dakota-build builddir default.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/default.mk default.build)
target := lib$(target).$(so_ext)

# include-dirs
include-dirs := $(patsubst %,--include-directory %,$(include-dirs))

# macros
macros := $(patsubst %,--define-macro %,$(macros))

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

single: $(srcs) | default.project
	for input in $(srcs); do\
    if [[ $$input =~ \.dk$$ ]]; then\
      $(DAKOTA-BASE) $(include-dirs) --compile --output $(builddir)/$$input.o $$input;\
    fi\
  done
	$(DAKOTA-BASE) --shared

check-exe: all
	echo "klass hashed-table; func main() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "builddir" => "dkt-exe" }' > exe.project
	rm -f exe
	DKT_EXCLUDE_LIBS=0 $(DAKOTA-BASE) --project exe.project exe.dk
	./exe

check: all
	dakota-catalog --silent $(target)
	$(MAKE) $(MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target)

clean: goal-clean | default.project
	$(DAKOTA-BASE) --clean
	$(RM) $(RMFLAGS) default.project
	$(RM) $(RMFLAGS) exe exe.dk exe.project
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) dkt-exe

distclean: clean
	cd $(rootdir); ./configure-common

install-dirs := $(DESTDIR)$(prefix)/{bin,include,lib/dakota/compiler-$(compiler)}

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install.files)

precompile:
	$(MAKE) $(MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files)
