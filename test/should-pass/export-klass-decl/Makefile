rootdir := ../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq) lib.$(SO_EXT)
	dakota --include-directory=. --output $@ $^

lib.$(SO_EXT): file-1.dk file-2.dk module-lib.dk
	dakota --shared --include-directory=. --output $@ $^

check:
	./$(target)

clean:
	rm -f ./$(target) file-{1,2}.o lib.$(SO_EXT) *~
	rm -rf obj
