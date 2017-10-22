# -*- mode: makefile -*-

prefix := ${HOME}/dakota

include ${prefix}/lib/dakota/platform.mk

$(shell mkdir -p $$HOME/dakota/z/build/dakota-dso)

.PHONY : all

all : ${HOME}/dakota/lib/libdakota-dso.dylib

${HOME}/dakota/lib/libdakota-dso.dylib : \
${HOME}/dakota/z/build/dakota-dso/dakota-dso.cc.o \
/usr/lib/libdl.dylib
	# generating $@
	@${cxx} -dynamiclib @${prefix}/lib/dakota/linker.opts -Wl,-rpath,${prefix}/lib -install_name @rpath/$(notdir $@) -o $@ $^

${HOME}/dakota/z/build/dakota-dso/dakota-dso.cc.o : \
${HOME}/dakota/dakota-dso/dakota-dso.cc
	# generating $@
	@${cxx} -c @${prefix}/lib/dakota/compiler.opts -I${prefix}/include -o $@ $<
