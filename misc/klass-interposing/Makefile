rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

%.$(so_ext): %.cc
	$(CXX) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAG) $@ -DNAME=\"$@\" $^

all: exe

exe: lib-1.$(so_ext) lib-2.$(so_ext) rt.$(so_ext)
	$(CXX) $(CXX_OUTPUT_FLAG) $@ -DNAME=\"$@\" $@.cc $^

lib-1.$(so_ext) lib-2.$(so_ext) ip-lib-a.$(so_ext) ip-lib-b.$(so_ext): rt.$(so_ext)

check: all ip-lib-a.$(so_ext) ip-lib-b.$(so_ext)
	$(LD_PRELOAD)="ip-lib-a.$(so_ext):ip-lib-b.$(so_ext)" ./exe

clean:
	rm -f exe *~ *.$(so_ext)

clone:
	cp lib-1.cc lib-2.cc
	cp lib-1.cc ip-lib-a.cc
	cp lib-1.cc ip-lib-b.cc
