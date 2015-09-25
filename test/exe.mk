include $(rootdir)/test/vars.mk

EXTRA_CXXFLAGS += --optimize=0 --debug=3 --define-macro DEBUG --no-warnings

exe: exe.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(so_ext): lib-%.dk module-lib-%.dk
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

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
