rootdir := ../../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	g++ -Wall -g3 --output $@ -ldl $^

check:
	./$(target) $(libdir)/libdakota.$(so_ext) $(libdir)/libdakota-util.$(so_ext)

clean:
	rm -f ./$(target) *~
