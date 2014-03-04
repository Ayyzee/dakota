include ../../../config.mk

%.$(SO_EXT): %.dk
	dakota --shared --output $@ $^

all: lib.$(SO_EXT)

check:
	otool -L lib.$(SO_EXT)

clean:
	rm -rf lib.$(SO_EXT) obj *~
