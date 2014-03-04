pl_files :=      $(wildcard *.pl)
pl_dot_files :=  $(pl_files:.pl=.pl.dot)
dot_files :=     $(wildcard *.dot)
dot_ps_files :=  $(dot_files:.dot=.dot.ps)  #$(pl_dot_files:.pl.dot=.pl.dot.ps)
dot_png_files := $(dot_files:.dot=.dot.png) #$(pl_dot_files:.pl.dot=.pl.dot.png)
png_files :=     $(dot_files:.dot=.png)
ps_files :=      $(dot_files:.dot=.ps)

DOT_FLAGS := -Gpage=8.5,11 -Gsize=7.5,10

%.png: %.dot
	dot -Tpng ${DOT_FLAGS} -o $(@) $(<)

%.dot.png: %.dot
	dot -Tpng ${DOT_FLAGS} -o $(@) $(<)

%.ps: %.dot
	dot -Tps2 ${DOT_FLAGS} -o $(@) $(<)

%.dot.ps: %.dot
	dot -Tps2 ${DOT_FLAGS} -o $(@) $(<)

#%.pl.dot: %.pl
#	./$(<) > $(@)

all: all-png

all-png:  $(dot_png_files)

all-ps:  $(dot_ps_files)

open-png: $(dot_png_files)
	open $^

open-ps: $(dot_ps_files)
	./bulk-open.sh $^

print-ps: $(dot_ps_files)
	lpr $^

clean:
	rm -rf $(dot_ps_files) $(dot_png_files) $(ps_files) $(png_files) *~
