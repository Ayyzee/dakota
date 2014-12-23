SHELL := /bin/sh -u

rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

EXTRA_DAKOTAFLAGS +=\
 --include-directory=.

../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^

name :=  $(shell $(rootdir)/bin/dakota-project name  --var SO_EXT=$(SO_EXT) --repository dakota-x.rep)
files := $(shell $(rootdir)/bin/dakota-project files --var SO_EXT=$(SO_EXT) --repository dakota-x.rep)

all: ../lib/$(lib_prefix)$(name)

check: ../lib/$(lib_prefix)$(name)
	dakota-introspector$(exeext) $<

../lib/$(lib_prefix)$(name): $(files)

install: ../lib/$(lib_prefix)$(name)
	sudo install -m 0755 $< $(DESTDIR)$(libdir)

uninstall:
	sudo rm -f $(DESTDIR)$(libdir)/$(lib_prefix)$(name)

clean:
	rm -f ../lib/$(lib_prefix)$(name)
	rm -rf obj
	rm -f *~
