SHELL := /bin/sh -u

rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA_VARS += DK_PREFIX=$(rootdir)

EXTRA_DAKOTAFLAGS :=\
 --include-directory=.\
 --include-directory=../include\

../lib/$(lib_prefix)%.$(so_ext):
	$(DAKOTA) --shared --output $@ --name $(libdir)/$(@F) --var MAKEFLAGS="$(MAKEFLAGS)" $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^

name :=  $(shell $(rootdir)/bin/dakota-project name  --var so_ext=$(so_ext))
files := $(shell $(rootdir)/bin/dakota-project files --var so_ext=$(so_ext))

LIB := ../lib/$(lib_prefix)$(name)

all: $(LIB)

check: all
	$(rootdir)/bin/dakota-info $(LIB)

$(LIB): $(files)

install: all
	sudo $(INSTALL) $(INSTALLFLAGS) -m 0755 $(LIB) $(DESTDIR)$(libdir)

uninstall:
	sudo $(RM) $(RMFLAGS) $(DESTDIR)$(libdir)/$(lib_prefix)$(name)

clean:
	$(RM) $(RMFLAGS) $(LIB)
	$(RM) $(RMFLAGS) obj
	$(RM) $(RMFLAGS) *~
