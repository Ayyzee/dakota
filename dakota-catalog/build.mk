# -*- mode: makefile -*-

$(shell mkdir -p $$HOME/dakota/z/build/dakota-catalog)

cxx :=    /usr/bin/clang++
prefix := ${HOME}/dakota

.PHONY : all

all : ${HOME}/dakota/bin/dakota-catalog

${HOME}/dakota/bin/dakota-catalog : \
${HOME}/dakota/z/build/dakota-catalog/dakota-catalog.cc.o \
${prefix}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -o $@ $^

${HOME}/dakota/z/build/dakota-catalog/dakota-catalog.cc.o : \
${HOME}/dakota/dakota-catalog/dakota-catalog.cc
	# generating $@
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
