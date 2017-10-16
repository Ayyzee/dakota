# -*- mode: makefile -*-

$(shell mkdir -p /Users/robert/dakota/zzz/build/dakota-catalog)

cxx :=    /usr/bin/clang++
prefix := /Users/robert/dakota

.PHONY : all dakota-catalog

all : dakota-catalog
dakota-catalog : /Users/robert/dakota/bin/dakota-catalog

/Users/robert/dakota/bin/dakota-catalog : /Users/robert/dakota/zzz/build/dakota-catalog/dakota-catalog.cc.o
	@if [[ $${silent:-0} == 0 ]]; then echo generating $@; fi
	@${cxx} @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -o $@ $^ ${prefix}/lib/libdakota-dso.dylib

/Users/robert/dakota/zzz/build/dakota-catalog/dakota-catalog.cc.o : /Users/robert/dakota/dakota-catalog/dakota-catalog.cc
	@if [[ $${silent:-0} == 0 ]]; then echo generating $@; fi
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
