include $(rootdir)/test/vars.mk

exe: exe.dk
	EXTRA_CXXFLAGS=$(CXX_NO_WARNINGS_FLAGS) $(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(so_ext): lib-%.dk module-lib-%.dk
	EXTRA_CXXFLAGS=$(CXX_NO_WARNINGS_FLAGS) $(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

.PHONY: all check clean

all: $(target)

$(target): $(prereq)

check: all
	if [[ -e $@.sh ]]; then ./$@.sh && touch failed-run; else ./exe && touch failed-run; fi

clean:
	$(RM) $(RMFLAGS) $(objdir-name)
	$(RM) $(RMFLAGS) failed-{build,run}
	$(RM) $(RMFLAGS) {exe,lib-{1,2,3}.$(so_ext)}
	$(RM) $(RMFLAGS) {exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	if [[ -e $@.sh ]]; then ./$@.sh; fi
