include ../../../config.mk

%.$(so_ext): %.dk
	dakota --shared --output $@ $^

all: lib.$(so_ext)

check:
	otool -L lib.$(so_ext)

clean:
	rm -rf lib.$(so_ext) obj *~
