# -*- mode: makefile -*-

$(shell mkdir -p /Users/robert/dakota/zzz/build/dakota-find-library)

cxx :=    /usr/bin/clang++
prefix := /Users/robert/dakota

.PHONY : all dakota-find-library

all : dakota-find-library
dakota-find-library : /Users/robert/dakota/bin/dakota-find-library

/Users/robert/dakota/bin/dakota-find-library : \
/Users/robert/dakota/zzz/build/dakota-find-library/dakota-find-library.cc.o \
${prefix}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -o $@ $^

/Users/robert/dakota/zzz/build/dakota-find-library/dakota-find-library.cc.o : \
/Users/robert/dakota/dakota-find-library/dakota-find-library.cc
	# generating $@
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
