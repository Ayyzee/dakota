set (install-lib-dakota-files
  ${source_dir}/lib/dakota/base.cmake
  ${source_dir}/lib/dakota/compiler-apple-clang.opts
  ${source_dir}/lib/dakota/compiler-gcc.opts
  ${source_dir}/lib/dakota/extra.json
  ${source_dir}/lib/dakota/lang-user-data.json
  ${source_dir}/lib/dakota/linker-apple-clang.opts
  ${source_dir}/lib/dakota/linker-gcc.opts
  ${source_dir}/lib/dakota/platform.yaml
  ${source_dir}/lib/dakota/used.json
  ${source_dir}/lib/dakota/dakota.pm
  ${source_dir}/lib/dakota/generate.pm
  ${source_dir}/lib/dakota/parse.pm
  ${source_dir}/lib/dakota/rewrite.pm
  ${source_dir}/lib/dakota/sst.pm
  ${source_dir}/lib/dakota/util.pm
)
set (install-include-files
  ${source_dir}/include/dakota-finally.h
  ${source_dir}/include/dakota-log.h
  ${source_dir}/include/dakota-object-defn.inc
  ${source_dir}/include/dakota-object.inc
  ${source_dir}/include/dakota-of.inc
  ${source_dir}/include/dakota-os.h
  ${source_dir}/include/dakota-other.inc
  ${source_dir}/include/dakota-weak-object-defn.inc
  ${source_dir}/include/dakota-weak-object.inc
  ${source_dir}/include/dakota.h
)
set (install-bin-files
  ${source_dir}/bin/dakota
  ${source_dir}/bin/dakota-parts
  ${source_dir}/bin/dakota-fixup-stderr
)
install (
  FILES ${install-lib-dakota-files}
  DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/dakota
)
install (
  FILES ${install-include-files}
  DESTINATION ${CMAKE_INSTALL_PREFIX}/include
)
install (
  PROGRAMS ${install-bin-files}
  DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
)
dk_install_symlink (
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/compiler-${cxx-compiler-id}.opts
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/compiler.opts
)
dk_install_symlink (
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/linker-${cxx-compiler-id}.opts
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/linker.opts
)
