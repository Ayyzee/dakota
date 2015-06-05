include ../../config.mk

bin/%: %.dk
	dakota --directory . --output $@ $^ /usr/local/lib/libdakota-util.$(so_ext)

all: bin/exe

check:
	bin/exe ../*.dk

clean:
	rm -rf bin obj *~
