rootdir := ../../..
include $(rootdir)/vars.mk

all:
	make --directory ../.. all install
	DK_NO_LINE= dakota --shared --output lib-1.$(so_ext) lib-1.dk

check:
	dakota-info lib-1.$(so_ext)

clean:
	rm -rf obj
	rm -f lib-1.$(so_ext) *~
