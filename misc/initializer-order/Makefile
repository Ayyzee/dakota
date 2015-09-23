rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

lib/%.$(so_ext): %.cc
	$(CXX) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAG) $@ $^

all: exe lib/lib-2.$(so_ext)

exe: lib/lib-1.$(so_ext) lib/lib-3.$(so_ext)
	$(CXX) $(CXX_OUTPUT_FLAG) $@ exe.cc $^

lib/lib-1.$(so_ext) lib/lib-2.$(so_ext): lib/lib-3.$(so_ext)

check: exe lib/lib-2.$(so_ext)
	$(LD_PRELOAD)="lib/lib-2.$(so_ext)" ./exe

clean:
	rm -f exe *~ lib/*.$(so_ext)
