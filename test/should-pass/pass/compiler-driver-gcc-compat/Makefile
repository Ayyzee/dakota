rootdir := ../../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	$(CP) $(CPFLAGS) exe.dk exe.cc
	$(CXX) --include-directory=. --output $@ exe.cc
	$(RM) $(RMFLAGS) exe.cc
	$(DAKOTA) --include-directory=. --output $@ exe.dk

check: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $(objdir)
	$(RM) $(RMFLAGS) $(target) exe.cc
	$(RM) $(RMFLAGS) $(target).$(cxx_debug_symbols_ext)
	$(RM) $(RMFLAGS) failed-{build,run}
	if [[ -e $@.sh ]]; then ./$@.sh; fi
