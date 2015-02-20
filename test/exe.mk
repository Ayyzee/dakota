include $(rootdir)/config.mk
include $(rootdir)/vars.mk

include $(rootdir)/test/vars.mk

exe: exe.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(SO_EXT): lib-%.dk module-lib-%.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

.PHONY: all check clean

all: $(target)

$(target): $(prereq)

check:
	@if [ -e $@.sh ]; then ./$@.sh; else LD_LIBRARY_PATH=. ./$(target) || touch failed-check; fi

clean:
	rm -rf obj exe lib-1.$(SO_EXT) lib-2.$(SO_EXT) failed-{build,check}
	@if [ -e $@.sh ]; then ./$@.sh; fi
