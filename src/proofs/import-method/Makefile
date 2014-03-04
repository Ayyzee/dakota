rootdir := ../../..
include $(rootdir)/vars.mk

all:
	EXTRA_CXXFLAGS="--all-warnings --ansi" dakota --output tst tst.dk

check:
	./tst

clean:
	rm -rf obj tst
