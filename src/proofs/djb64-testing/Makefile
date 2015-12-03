rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_DEBUG_FLAGS) --include-directory $(rootdir)/include $(CXX_OUTPUT_FLAGS) example-test example-test.cc

test: all
	./test.sh

check: test

clean:
	rm -rf example-test example-test.dSYM hashes-{words,numbers}.txt hashes-{words,numbers}-sorted-unique.txt numbers.txt obj *~
