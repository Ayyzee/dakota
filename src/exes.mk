rootdir := ..

include $(rootdir)/dakota.mk

exes := $(blddir)/tst $(blddir)/min $(blddir)/dummy

.PHONY:\
 all\
 check\
 clean\
#
all: $(exes)

check: all
	for exe in $(exes); do echo $$exe; $$exe; done

clean:
	$(RM) $(RMFLAGS) $(exes)
	for exe in $(exes); do $(RM) $(RMFLAGS) $$exe $$exe.$(cxx_debug_symbols_ext); $(RM) $(RMFLAGS) $(objdir)/{nrt,rt,}/$$exe{-main,}.*; done

$(blddir)/tst:   $(blddir)/../lib/libdakota-util.$(so_ext)

$(blddir)/min:   $(blddir)/../lib/libdakota.$(so_ext)

$(blddir)/dummy: $(srcdir)/dummy-main.$(cc_ext)
