rootdir := ..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

EXTRA_DAKOTAFLAGS += --include-directory .

fail_exe_files := fail-exe-files.mk

%/exe: %/exe.dk
	$(DAKOTA) --directory $(dir $@) --output $(notdir $@) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $(notdir $^) /usr/local/lib/libdakota-util.$(SO_EXT)

%/lib-1.$(SO_EXT): %/lib-1.dk %/module-lib-1.dk
	$(DAKOTA) --shared --directory $(dir $@) --output $(notdir $@) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $(notdir $^) /usr/local/lib/libdakota-util.$(SO_EXT)

%/lib-2.$(SO_EXT): %/lib-2.dk %/module-lib-2.dk
	$(DAKOTA) --shared --directory $(dir $@) --output $(notdir $@) $(EXTRA_DAKOTAFLAGS) $(DAKOTAFLAGS) $(notdir $^) /usr/local/lib/libdakota-util.$(SO_EXT)

should_pass_file := should-pass.mk
should_pass_exe_files := $(shell ./gen.pl should-pass $(should_pass_file))
should_pass_dirs := $(dir $(should_pass_exe_files))

should_fail_file := should-fail.mk
should_fail_exe_files := $(shell ./gen.pl should-fail $(should_fail_file))
should_fail_dirs := $(dir $(should_fail_exe_files))

.PHONY: all check clean

all: $(should_pass_exe_files)

include $(should_pass_file)
include $(should_fail_file)

check:
	./check.pl --output $(fail_exe_files) $(should_pass_dirs) | tee check
	@echo
	@cat $(fail_exe_files)
clean:
	for dir in $(should_pass_dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
	for dir in $(should_fail_dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
	rm -f $(should_pass_file) $(should_fail_file) $(fail_exe_files) check
	rm -f *~
