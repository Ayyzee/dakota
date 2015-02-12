rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) $(CXX_OUTPUT_FLAGS) example example.cc
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) $(CXX_OUTPUT_FLAGS) example-test example-test.cc

test: all
	./test.sh

check: test

clean:
	rm -rf example example-test example.dSYM example-test.dSYM hashes-{words,numbers}.txt hashes-{words,numbers}-sorted-unique.txt numbers.txt *~
