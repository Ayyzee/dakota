rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%.$(SO_EXT): %.cc
	$(CXX) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAG) $@ -DNAME=\"$@\" $^

all: exe

exe: lib-1.$(SO_EXT) lib-2.$(SO_EXT) rt.$(SO_EXT)
	$(CXX) $(CXX_OUTPUT_FLAG) $@ -DNAME=\"$@\" $@.cc $^

lib-1.$(SO_EXT) lib-2.$(SO_EXT) ip-lib-a.$(SO_EXT) ip-lib-b.$(SO_EXT): rt.$(SO_EXT)

check: all ip-lib-a.$(SO_EXT) ip-lib-b.$(SO_EXT)
	$(LD_PRELOAD)="ip-lib-a.$(SO_EXT):ip-lib-b.$(SO_EXT)" ./exe

clean:
	rm -f exe *~ *.$(SO_EXT)

clone:
	cp lib-1.cc lib-2.cc
	cp lib-1.cc ip-lib-a.cc
	cp lib-1.cc ip-lib-b.cc
