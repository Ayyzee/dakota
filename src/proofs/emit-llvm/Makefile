rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all: lib-1.$(so_ext)
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_COMPILE_FLAGS) exe-main.cc
	/usr/local/bin/clang++ --output exe-cc exe-cc.bc

lib-1.$(so_ext): lib-1-1.cc lib-1-2.cc
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_COMPILE_FLAGS) $^
	/usr/local/bin/clang++ $(CXXFLAGS) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ lib-1-1.bc lib-1-2.bc

check: all
	./exe-cc

clean:
	rm -rf exe-cc exe-cc.{bc,ll,s} lib-1.$(so_ext) *.bc exe-cc.dSYM *~
