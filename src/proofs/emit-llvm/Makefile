rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all: lib-1.$(SO_EXT)
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_COMPILE_FLAGS) exe.cc
	/usr/local/bin/clang++ --output exe exe.bc

lib-1.$(SO_EXT): lib-1-1.cc lib-1-2.cc
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_COMPILE_FLAGS) $^
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ lib-1-1.bc lib-1-2.bc

check: all
	./exe

clean:
	rm -rf exe exe.{bc,ll,s} lib-1.$(SO_EXT) *.bc exe.dSYM *~
