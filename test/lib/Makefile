rootdir := ../..

target-base := l1
so_ext := dylib

builddir := $(shell $(rootdir)/bin/dakota-build builddir --build project)
include $(shell $(rootdir)/bin/dakota-build2mk --output $(builddir)/project.mk project)

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
	$(DAKOTA-BASE) --shared --project project $^

no-project:
	$(DAKOTA-BASE) --shared --output $(target) $^

check: all
	dakota-catalog $(target)

clean:
	$(RM) $(RMFLAGS) $(builddir)
	$(RM) $(RMFLAGS) $(target) project.mk
