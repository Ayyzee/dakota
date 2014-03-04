rootdir := ../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq) lib.dk
	dakota --output $@ $^ $(libdir)/libdakota-util.$(SO_EXT)

lib.dk:
	dakota-introspector --output $@ $(libdir)/libdakota-util.$(SO_EXT)

check:
	dakota-introspector --output dumped-lib.dk $(target)
	diff --minimal lib.dk dumped-lib.dk; exit 0

clean:
	rm -f ./$(target) dumped-lib.dk lib.dk *~
	rm -rf obj
