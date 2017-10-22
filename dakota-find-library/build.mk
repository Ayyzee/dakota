# -*- mode: makefile -*-

$(shell mkdir -p $$HOME/dakota/z/build/dakota-find-library)

cxx :=    /usr/bin/clang++
prefix := ${HOME}/dakota

.PHONY : all

all : ${HOME}/dakota/bin/dakota-find-library

${HOME}/dakota/bin/dakota-find-library : \
${HOME}/dakota/z/build/dakota-find-library/dakota-find-library.cc.o \
${prefix}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -o $@ $^

${HOME}/dakota/z/build/dakota-find-library/dakota-find-library.cc.o : \
${HOME}/dakota/dakota-find-library/dakota-find-library.cc
	# generating $@
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
