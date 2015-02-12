rootdir := ../../..
include $(rootdir)/config.mk
include $(rootdir)/vars.mk

CXX_INLINE_FLAGS := -Winline --define-macro should_inline

all:
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) -O3 -S inline-unbox.cc
	mv inline-unbox.s inline-unbox-noattrs.s
	$(CXX) $(CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_INLINE_FLAGS) -O3 -S inline-unbox.cc
	mv inline-unbox.s inline-unbox-attrs.s

diff: all
	#diff inline-unbox-noattrs.s inline-unbox-attrs.s || true
	#@echo --line-count--
	@wc -l -c inline-unbox-noattrs.s
	@wc -l -c inline-unbox-attrs.s

clang-macros:
	clang -dM -E -x c /dev/null

check: all

clean:
	rm -f inline-unbox.o inline-unbox.s inline-unbox-{attrs,noattrs}.s *~
