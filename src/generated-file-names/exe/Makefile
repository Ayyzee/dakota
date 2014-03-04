include ../../../config.mk

%: %.dk
	dakota --output $@ $^

all: exe

check:
	otool -L exe

clean:
	rm -rf ./exe obj *~
