rootdir := ../..

DOT_FLAGS := -Gpage=8.5,11 -Gsize=7.5,10

%.ps: %.dot
	dot -Tps2 ${DOT_FLAGS} -o $@ $<

%.pl: %.dk
	$(rootdir)/bin/macro-system-parser.pl $< > $@

.PHONY: all clean

all: all-macros.pl macro-syntax-fsm.ps
	path=$$PWD/all-macros.pl
	DK_MACROS_PATH=$$path $(rootdir)/lib/dakota/macro_system.pm all.dk

all-macros.pl: all-macros.dk

macro-syntax-fsm.ps: macro-syntax-fsm.dot

clean:
	rm -fr all-macros.pl macro-system-test-output macro-syntax-fsm.ps *~
