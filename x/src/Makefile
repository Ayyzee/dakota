rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA := dakota

DAKOTAFLAGS +=\
 --include-directory=$(srcdir)/.\
 --include-directory=../include\
 --include-directory=$(rootdir)/include\

export CXXFLAGS := --all-warnings --debug=3

../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ --name $(libdir)/$(@F) $(DAKOTAFLAGS) $^

name :=  $(shell dakota-project name  --var SO_EXT=$(SO_EXT) --repository dakota-x.rep)
files := $(shell dakota-project files --var SO_EXT=$(SO_EXT) --repository dakota-x.rep)

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
