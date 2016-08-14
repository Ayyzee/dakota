rootdir := ..

srcdir := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

export DKT_EXCLUDE_LIBS = 2

builddir := $(shell $(rootdir)/bin/dakota-build builddir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/dakota.mk dakota.build)
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
	echo "klass hashed-table; func main() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > exe.dk
	echo '{ "srcs" => [ "exe.dk" ], "builddir" => "dkt-exe" }' > exe.project
	rm -f exe
	DKT_EXCLUDE_LIBS=0 $(DAKOTA) --project exe.project
	./exe

check: all
	dakota-catalog --silent $(target)
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) check-exe

installcheck: check install
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) install # hackhack: the 'install' on the RHS of the phony installcheck target should take care of this
	if [[ -e $@.sh ]]; then ./$@.sh; fi

goal-clean:
	$(RM) $(RMFLAGS) $(target)

clean: goal-clean | dakota.project
	$(DAKOTA-BASE) --clean
	$(RM) $(RMFLAGS) dakota.project
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
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) DAKOTAFLAGS=--$@ all

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files)
