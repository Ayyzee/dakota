rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNING_FLAGS) $(CXX_DEBUG_FLAGS) $(CXX_OUTPUT_FLAGS) ./exe exe.cc

check:
	./exe

clean:
	rm -rf ./exe ./exe.dSYM *~
