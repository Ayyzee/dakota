# -*- mode: makefile -*-

source_dir := ${HOME}/dakota
prefix_dir := ${HOME}/dakota

include ${prefix_dir}/lib/dakota/platform.mk

$(shell mkdir -p ${source_dir}/z/build/dakota-find-library)

.PHONY : all

all : ${source_dir}/bin/dakota-find-library

${source_dir}/bin/dakota-find-library : \
${source_dir}/z/build/dakota-find-library/dakota-find-library.cc.o \
${prefix_dir}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix_dir}/lib/dakota/linker.opts -Wl,-rpath,${prefix_dir}/lib -o $@ $^

${source_dir}/z/build/dakota-find-library/dakota-find-library.cc.o : \
${source_dir}/dakota-find-library/dakota-find-library.cc
	# generating $@
	@${cxx} -c @${prefix_dir}/lib/dakota/compiler.opts -I${prefix_dir}/include -o $@ $<
