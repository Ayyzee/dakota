rootdir := ../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	g++ -Wall -g3 --output $@ -ldl $^

check:
	./$(target) $(libdir)/libdakota.$(SO_EXT) $(libdir)/libdakota-util.$(SO_EXT)

clean:
	rm -f ./$(target) *~
