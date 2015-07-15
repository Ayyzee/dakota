#rootdir := ../../..
#include $(rootdir)/config.mk
#include $(rootdir)/vars.mk

so_ext := dylib

.PHONY: all clean check

%.$(so_ext): %.cc
	clang++ -std=c++11 --shared -fPIC -Weverything -Wno-pedantic -Wno-old-style-cast -Wno-c99-extensions -Wno-c++98-compat-pedantic --output $@ $^

%: %.cc
	clang++ -std=c++11 -Weverything -Wno-pedantic -Wno-old-style-cast -Wno-c99-extensions -Wno-c++98-compat-pedantic --output $@ $^

all: exe exe-w-lib

exe: set-read-only.cc

exe-w-lib: exe.cc set-read-only.$(so_ext)
	clang++ -std=c++11 -Weverything -Wno-old-style-cast -Wno-c99-extensions -Wno-c++98-compat-pedantic --output $@ $^

check: all
	./exe || true
	./exe-w-lib || true

clean:
	rm -rf set-read-only.$(so_ext) exe exe-w-lib 
