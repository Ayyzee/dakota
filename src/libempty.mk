rootdir := ..

include $(rootdir)/dakota.mk

exes := $(blddir)/tst $(blddir)/min $(blddir)/dummy

.PHONY:\
 all\
 check\
 clean\

all:
	cat /dev/null > libempty.$(cc_ext)
	clang++ -std=c++11 --shared -fPIC --output ../lib/libempty.$(so_ext) libempty.$(cc_ext)

check: all

clean:
	rm -f libempty.$(so_ext) libempty.$(cc_ext)
