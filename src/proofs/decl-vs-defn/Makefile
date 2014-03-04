rootdir := ../../..
include $(rootdir)/vars.mk

all:
	make --directory ../.. all install
	DK_NO_LINE= dakota --shared --output lib-1.$(SO_EXT) lib-1.dk

check:
	dakota-introspector lib-1.$(SO_EXT)

clean:
	rm -rf obj
	rm -f lib-1.$(SO_EXT) *~
