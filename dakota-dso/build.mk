# -*- mode: makefile -*-

source_dir := ${HOME}/dakota
prefix_dir := ${HOME}/dakota

include ${prefix_dir}/lib/dakota/platform.mk

$(shell mkdir -p ${source_dir}/z/build/dakota-dso)

.PHONY : all

all : ${source_dir}/lib/libdakota-dso.dylib

${source_dir}/lib/libdakota-dso.dylib : \
${source_dir}/z/build/dakota-dso/dakota-dso.cc.o \
/usr/lib/libdl.dylib
	# generating $@
	@${cxx} -dynamiclib @${prefix_dir}/lib/dakota/linker.opts -Wl,-rpath,${prefix_dir}/lib -install_name @rpath/$(notdir $@) -o $@ $^

${source_dir}/z/build/dakota-dso/dakota-dso.cc.o : \
${source_dir}/dakota-dso/dakota-dso.cc
	# generating $@
	@${cxx} -c @${prefix_dir}/lib/dakota/compiler.opts -I${prefix_dir}/include -o $@ $<
