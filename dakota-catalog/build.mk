# -*- mode: makefile -*-

$(shell mkdir -p /Users/robert/dakota/zzz/build/dakota-catalog)

cxx :=    /usr/bin/clang++
prefix := /Users/robert/dakota

.PHONY : all

all : /Users/robert/dakota/bin/dakota-catalog

/Users/robert/dakota/bin/dakota-catalog : \
/Users/robert/dakota/zzz/build/dakota-catalog/dakota-catalog.cc.o \
${prefix}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -o $@ $^

/Users/robert/dakota/zzz/build/dakota-catalog/dakota-catalog.cc.o : \
/Users/robert/dakota/dakota-catalog/dakota-catalog.cc
	# generating $@
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
