rootdir := ../../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq)
	clang --all-warnings --debug=3 --output $@ -ldl $^

check:
	./$(target) $(prefix)/lib/libdakota.$(so_ext) $(prefix)/lib/libdakota-util.$(so_ext)

clean:
	$(RM) $(RMFLAGS) ./$(target) *~
