
# below this line is an experiment

build-fail: $(fail_exe_files)
	$(MAKE) build-fail-clean
	-$(MAKE) build-fail-all
	$(MAKE) build-fail-check
build-fail-all: $(fail_exe_files) $(build_fail_exe_files)
build-fail-check: $(fail_exe_files)
	./check.pl $(build_fail_exe_files)
build-fail-clean: $(fail_exe_files)
	dirs=`./dirs.pl $(build_fail_exe_files)` && for dir in $$dirs; do echo "cd $$dir" ; $(MAKE) --directory $$dir clean ; done

run-fail: $(fail_exe_files)
	$(MAKE) run-fail-clean
	-$(MAKE) run-fail-all
	$(MAKE) run-fail-check
run-fail-all: $(fail_exe_files) $(run_fail_exe_files)
run-fail-check: $(fail_exe_files)
	./check.pl $(run_fail_exe_files)
run-fail-clean:
	dirs=`./dirs.pl $(run_fail_exe_files)` && for dir in $$dirs; do echo "cd $$dir" ; $(MAKE) --directory $$dir clean ; done

fail:       build-fail       run-fail
fail-all:   build-fail-all   run-fail-all
fail-check: build-fail-check run-fail-check
fail-clean: build-fail-clean run-fail-clean
