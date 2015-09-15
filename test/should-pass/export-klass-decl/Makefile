rootdir := ../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq) lib.$(so_ext)
	dakota --include-directory=. --output $@ $^

lib.$(so_ext): file-1.dk file-2.dk module-lib.dk
	dakota --shared --include-directory=. --output $@ $^

check:
	./$(target)

clean:
	rm -f ./$(target) file-{1,2}.o lib.$(so_ext) *~
	rm -rf obj
