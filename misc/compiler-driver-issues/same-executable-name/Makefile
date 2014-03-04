rootdir := ../../..

include $(rootdir)/config.mk

all: test

test: test.dk
	dakota --output $@ $^

check: test

clean:
	rm -rf obj bin test *~
