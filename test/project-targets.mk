.PHONY: all check clean

all: $(target)
	if [[ -e $@.sh ]]; then ./$@.sh $(target); fi

$(target): $(prereq)

check: all
	if [[ -e $@.sh ]]; then ./$@.sh $(rootdir)/test/bin/run-with-timeout 3 ./$(target); else $(rootdir)/test/bin/run-with-timeout 3 ./$(target); fi

clean:
	$(RM) $(RMFLAGS) $(objdir-name)
	$(RM) $(RMFLAGS) {exe,exe-cc,lib-{1,2,3}.$(so_ext)}
	$(RM) $(RMFLAGS) {exe,exe-cc,lib-{1,2,3}.$(so_ext)}.$(cxx_debug_symbols_ext)
	if [[ -e $@.sh ]]; then ./$@.sh $(target); fi
