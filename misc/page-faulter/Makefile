rootdir := ../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	g++ --all-warnings --debug=3 --output page-faulter page-faulter-main.cc pg.cc

test: all
	./page-faulter

clean:
	rm -f page-faulter *~
