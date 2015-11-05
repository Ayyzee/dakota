#rootdir := ../../..
# include $(rootdir)/config.mk
# include $(rootdir)/vars.mk

so_ext := dylib

.PHONY: all clean check

%.$(so_ext): %.cc
	clang++ -std=c++11 --shared -fPIC -Weverything -Wno-pedantic -Wno-old-style-cast -Wno-c99-extensions -Wno-c++98-compat-pedantic --output $@ $^

%: %.cc
	clang++ -std=c++11 -Weverything -Wno-pedantic -Wno-old-style-cast -Wno-c99-extensions -Wno-c++98-compat-pedantic --output $@ $^

all: exe-cc

check: all
	./exe-cc

clean:
	rm -rf set-read-only.$(so_ext) exe-cc exe-cc-w-lib 
