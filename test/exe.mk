include $(rootdir)/test/vars.mk

exe: exe.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(so_ext): lib-%.dk module-lib-%.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

.PHONY: all check clean

all: $(target)

$(target): $(prereq)

check:
	@if [ -e $@.sh ]; then ./$@.sh; else LD_LIBRARY_PATH=. ./$(target) || touch failed-check; fi

clean:
	rm -rf obj exe lib-1.$(so_ext) lib-2.$(so_ext) failed-{build,check}
	@if [ -e $@.sh ]; then ./$@.sh; fi
