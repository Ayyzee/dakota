# -*- mode: makefile -*-

source_dir := ${HOME}/dakota
prefix_dir := ${HOME}/dakota

include ${prefix_dir}/lib/dakota/platform.mk

$(shell mkdir -p ${source_dir}/z/build/dakota-catalog)

.PHONY : all

all : ${source_dir}/bin/dakota-catalog

${source_dir}/bin/dakota-catalog : \
${source_dir}/z/build/dakota-catalog/dakota-catalog.cc.o \
${prefix_dir}/lib/libdakota-dso.dylib
	# generating $@
	@${cxx} @${prefix_dir}/lib/dakota/linker.opts -Wl,-rpath,${prefix_dir}/lib -o $@ $^

${source_dir}/z/build/dakota-catalog/dakota-catalog.cc.o : \
${source_dir}/dakota-catalog/dakota-catalog.cc
	# generating $@
	@${cxx} -c @${prefix_dir}/lib/dakota/compiler.opts -I${prefix_dir}/include -o $@ $<
