rootdir := ../..

so_ext := dylib

builddir := $(shell $(rootdir)/bin/dakota-build builddir --build dakota.project)
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/dakota.mk dakota.project)
target := lib$(target).$(so_ext)

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PHONY:\
 all\
 check\
 clean\
 no-project\

all: $(target)

$(target):
	$(DAKOTA-BASE) --project dakota.project

no-project:
	$(DAKOTA-BASE) --shared --output $(target) $^

check: all
	dakota-catalog $(target)

clean:
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) $(target) dakota.mk
