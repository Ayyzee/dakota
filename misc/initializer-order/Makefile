rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

lib/%.$(SO_EXT): %.cc
	$(CXX) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAG) $@ $^

all: exe lib/lib-2.$(SO_EXT)

exe: lib/lib-1.$(SO_EXT) lib/lib-3.$(SO_EXT)
	$(CXX) $(CXX_OUTPUT_FLAG) $@ exe.cc $^

lib/lib-1.$(SO_EXT) lib/lib-2.$(SO_EXT): lib/lib-3.$(SO_EXT)

check: exe lib/lib-2.$(SO_EXT)
	$(LD_PRELOAD)="lib/lib-2.$(SO_EXT)" ./exe

clean:
	rm -f exe *~ lib/*.$(SO_EXT)
