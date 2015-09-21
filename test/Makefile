rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%/exe: %/exe.dk
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

%/exe: %/exe.cc
	DKT_INITIAL_WORKDIR=$(PWD) $(MAKE) $(MAKEFLAGS) --directory $(dir $@) $(notdir $@) || touch $(dir $@)/failed-build

.PHONY: \
 all\
 all-should-pass-pass\
 all-should-pass-fail\
 all-should-fail\
 clean\
 clean-should-pass-pass\
 clean-should-pass-fail\
 clean-should-fail\
#

all-should-pass-pass := $(shell ./bin/generate-phony-targets-1.sh should-pass/pass)
all-should-pass-fail := $(shell ./bin/generate-phony-targets-1.sh should-pass/fail)
all-should-fail :=      $(shell ./bin/generate-phony-targets-1.sh should-fail)

all: all-should-pass-pass all-should-pass-fail all-should-fail

all-should-pass-pass: $(all-should-pass-pass)
all-should-pass-fail: $(all-should-pass-fail)
all-should-fail:      $(all-should-fail)

clean: clean-should-pass-pass clean-should-pass-fail clean-should-fail
	$(RM) $(RMFLAGS) obj

clean-should-pass-pass:
	$(RM) $(RMFLAGS) should-pass/pass/*/failed-{build,run}
	$(RM) $(RMFLAGS) should-pass/pass/*/obj
	$(RM) $(RMFLAGS) should-pass/pass/*/{exe,lib-{1,2,3}.$(so_ext)}
	$(RM) $(RMFLAGS) should-pass/pass/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	bin/run-each-script-in-dir.sh should-pass/pass/*/clean.sh

clean-should-pass-fail:
	$(RM) $(RMFLAGS) should-pass/fail/*/failed-{build,run}
	$(RM) $(RMFLAGS) should-pass/fail/*/obj
	$(RM) $(RMFLAGS) should-pass/fail/*/{exe,lib-{1,2,3}.$(so_ext)}
	$(RM) $(RMFLAGS) should-pass/fail/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	bin/run-each-script-in-dir.sh should-pass/fail/*/clean.sh

clean-should-fail:
	$(RM) $(RMFLAGS) should-fail/*/failed-{build,run}
	$(RM) $(RMFLAGS) should-fail/*/obj
	$(RM) $(RMFLAGS) should-fail/*/{exe,lib-{1,2,3}.$(so_ext)}
	$(RM) $(RMFLAGS) should-fail/*/{exe,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	bin/run-each-script-in-dir.sh should-fail/*/clean.sh
