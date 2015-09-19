rootdir := ../../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	dakota --include-directory=. --output $@ exe.dk
	cp exe.dk exe.cc
	g++ --include-directory=. --output $@ exe.cc
	rm exe.cc

check:
	./$(target)
clean:
	rm -f ./$(target) exe.cc *~
	rm -rf obj
