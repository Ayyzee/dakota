%.png: %.dot
	dot -Gsize="5,7" -Tpng -o $(@) $(<)

all: collection-set-klasses.png inherit+instant-1.png inherit+instant-2.png
	open hackers.html

clean:
	rm -f *.png *~
