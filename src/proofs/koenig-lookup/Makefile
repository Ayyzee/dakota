rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_OUTPUT_FLAGS) exe exe.cc

check: all
	./exe

clean:
	rm -rf exe exe.dSYM *~
