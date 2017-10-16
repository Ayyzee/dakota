# -*- mode: makefile -*-

$(shell mkdir -p /Users/robert/dakota/zzz/build/dakota-dso)

cxx :=    /usr/bin/clang++
prefix := /Users/robert/dakota

.PHONY : all libdakota-dso

all : libdakota-dso
libdakota-dso : /Users/robert/dakota/lib/libdakota-dso.dylib

/Users/robert/dakota/lib/libdakota-dso.dylib : /Users/robert/dakota/zzz/build/dakota-dso/dakota-dso.cc.o
	${cxx} -dynamiclib @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -install_name @rpath/$(notdir $@) -o $@ $^ /usr/lib/libdl.dylib

/Users/robert/dakota/zzz/build/dakota-dso/dakota-dso.cc.o : /Users/robert/dakota/dakota-dso/dakota-dso.cc
	${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
