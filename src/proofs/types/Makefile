rootdir := ../../..

include $(rootdir)/vars.mk

%.dot.ps: %.dot
	dot -Tps2 -o $(@) $(<)

%.pl.dot: %.pl
	./gen.pl $< --dot $@ --txt $<.txt

%.o: %.cc
	g++ --compile -fPIC --include-directory $(rootdir)/include $(EXTRA_CXXFLAGS) --output $@ $^

all: type.pl.dot
	open $^
	cat type.pl.txt

check: const.o

print:
	dot -Tps2 -Gpage=8.5,11 -Gsize=10,7.5 -Grotate=90 -o type.pl.dot.ps type.pl.dot
	lpr type.pl.dot.ps

clean:
	rm -f type.o type.pl.dot.ps type.pl.dot type.pl.txt *~
