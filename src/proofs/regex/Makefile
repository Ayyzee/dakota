rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) $(CXX_OUTPUT_FLAGS) exe exe.cc

check: all
	./exe

clean:
	rm -rf exe exe.dSYM *~
