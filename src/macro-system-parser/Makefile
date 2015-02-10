rootdir := ../..
DK_PREFIX := ../..

%.pl: %.dk
	./macro-system-parser.pl $< > $@

.PHONY: all clean

all: all-macros.pl
	DK_PREFIX=$(DK_PREFIX) MACROS=$< $(rootdir)/lib/dakota/macro_system.pm all.dk

clean:
	rm -fr all-macros.pl obj-macro-system
