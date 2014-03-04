rootdir := ../../..

include $(rootdir)/config.mk

all: test.$(SO_EXT)

test.$(SO_EXT): test.dk
	dakota --shared --output $@ $^

check: test.$(SO_EXT)

clean:
	rm -rf obj lib test.$(SO_EXT) *~
