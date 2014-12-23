rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA := dakota

DAKOTAFLAGS +=\
 --include-directory=$(srcdir)/.\
 --include-directory=../include\
 --include-directory=$(rootdir)/include\


EXTRA_DAKOTAFLAGS ?=
export CXXFLAGS := --all-warnings --debug=3

../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ --name $(libdir)/$(@F) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^

name :=  $(shell dakota-project name  --var SO_EXT=$(SO_EXT))
files := $(shell dakota-project files --var SO_EXT=$(SO_EXT))

all: ../lib/$(name)

check: ../lib/$(name)
	dakota-introspector$(exeext) $<

../lib/$(name): $(files)

install: ../lib/$(name)
	sudo install -m 0755 $< $(DESTDIR)$(libdir)

uninstall:
	sudo rm -f $(DESTDIR)$(libdir)/$(name)

clean:
	rm -f ../lib/$(name)
	rm -rf obj
	rm -f *~
