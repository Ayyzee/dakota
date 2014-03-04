rootdir := ../..

%.pl: %.dk
	./macro-system-parser.pl $< > $@

.PHONY: all clean

all: all-macros.pl
	MACROS=$< ./macro-system.pl all.dk > all.cc
	cat all.cc

clean:
	rm -f all-macros.pl all.cc
