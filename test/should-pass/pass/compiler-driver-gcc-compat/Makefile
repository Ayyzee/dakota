rootdir := ../../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	cp exe.dk exe.cc
	$(CXX) --include-directory=. --output $@ exe.cc
	$(DAKOTA) --include-directory=. --output $@ exe.dk

check: all
	./$(target)

clean:
	rm -f  $(target) exe.cc
	rm -fr $(target).$(cxx_debug_symbols_ext)
	rm -f  failed-{build,run}
	rm -fr $(objdir)
	if [[ -e $@.sh ]]; then ./$@.sh; fi
