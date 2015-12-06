rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	CXX=$(CXX) ./generate-compiler-default-argument-promotions.pl

install:
	cp compiler-default-argument-promotions.json ../../../lib/dakota

clean:
	rm -f type-index
	rm -f compiler-default-argument-promotions.json
