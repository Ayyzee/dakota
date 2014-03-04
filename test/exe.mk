rootdir := $(shell dk-rootdir.pl $(rootdir))

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

include $(rootdir)/test/vars.mk

%: %.dk
	$(DAKOTA) --output $@ $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^

lib-%.$(SO_EXT): lib-%.dk module-lib-%.dk
	$(DAKOTA) --shared --output $@ $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $^

.PHONY: all check clean

all: $(target)

$(target): $(prereq)

check:
	@if [ -e $@.sh ]; then ./$@.sh; else name=`dk name`; LD_LIBRARY_PATH=. ./$$name; fi

clean:
	rm -rf obj exe lib-1.$(SO_EXT) lib-2.$(SO_EXT)
	@if [ -e $@.sh ]; then ./$@.sh; fi
