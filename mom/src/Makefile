SHELL := /bin/sh -u

rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA_VARS += DK_PREFIX=$(rootdir)

EXTRA_DAKOTAFLAGS +=\
 --include-directory=.\
 --include-directory=../include\

../lib/$(lib_prefix)%.$(SO_EXT):
	$(DAKOTA) --keep-going --shared --output $@ --name $(libdir)/$(@F) --var MAKEFLAGS="$(MAKEFLAGS)" $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^
	echo $(MAKEFLAGS)

name :=  $(shell $(rootdir)/bin/dakota-project name  --var SO_EXT=$(SO_EXT))
files := $(shell $(rootdir)/bin/dakota-project files --var SO_EXT=$(SO_EXT))

LIB := ../lib/$(name)

all: $(LIB)

check: all
	$(rootdir)/bin/dakota-info$(exeext) $(LIB)

$(LIB): $(files)

install: all
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $(LIB) $(DESTDIR)$(libdir)

uninstall:
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(libdir)/$(name)

clean:
	$(RM) $(RMFLAGS) $(LIB)
	$(RM) $(RMFLAGS) obj
	$(RM) $(RMFLAGS) *~
