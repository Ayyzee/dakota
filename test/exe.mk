include $(rootdir)/test/vars.mk

exe: exe.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(so_ext): lib-%.dk module-lib-%.dk
	EXTRA_CXXFLAGS="$(EXTRA_CXXFLAGS)" $(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

.PHONY: all check clean

all: $(target)

$(target): $(prereq)

check: all
	if [[ -e $@.sh ]]; then ./$@.sh; else ./exe; fi

clean:
	rm -f  {exe,lib-{1,2,3}.$(so_ext)}
	rm -fr {exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	rm -f  failed-build
	rm -fr $(objdir)
	if [[ -e $@.sh ]]; then ./$@.sh; fi
