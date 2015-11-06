rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) --output exe-cc exe-main.cc

check: all
	./exe-cc

clean:
	rm -rf exe-cc exe-cc.dSYM *~
