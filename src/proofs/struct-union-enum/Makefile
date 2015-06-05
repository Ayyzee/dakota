rootdir := ../../..
include $(rootdir)/vars.mk

all:
	make --directory ../.. all install
	DK_NO_LINE= dakota --shared --output k0123.$(so_ext) k0123.dk

check:
	dakota-introspector k0123.$(so_ext)

clean:
	rm -rf obj
	rm -f k0123.$(so_ext) *~
