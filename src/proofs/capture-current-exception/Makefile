rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) --output exe exe.cc

check: all
	./exe

clean:
	rm -rf exe exe.dSYM *~
