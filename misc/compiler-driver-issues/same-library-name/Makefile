rootdir := ../../..

include $(rootdir)/config.mk

all: test.$(so_ext)

test.$(so_ext): test.dk
	dakota --shared --output $@ $^

check: test.$(so_ext)

clean:
	rm -rf obj lib test.$(so_ext) *~
