rootdir := ../../../..

include $(rootdir)/test/vars.mk
include $(rootdir)/test/project-vars.mk
include $(rootdir)/test/rules.mk

.PHONY:\
 all\
 check\
 clean\

all:
	cat /dev/null > libempty.$(cc_ext)
	clang++ -std=c++11 --shared -fPIC --output ./libempty.$(so_ext) libempty.$(cc_ext)

check: all

clean:
	$(RM) $(RMFLAGS) libempty.$(so_ext) libempty.$(cc_ext)
