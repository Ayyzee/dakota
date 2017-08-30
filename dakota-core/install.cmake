set (install-lib-dakota-files
  ${source-dir}/lib/dakota/base.cmake
  ${source-dir}/lib/dakota/compiler-apple-clang.opts
  ${source-dir}/lib/dakota/compiler-gcc.opts
  ${source-dir}/lib/dakota/extra.json
  ${source-dir}/lib/dakota/lang-user-data.json
  ${source-dir}/lib/dakota/linker-apple-clang.opts
  ${source-dir}/lib/dakota/linker-gcc.opts
  ${source-dir}/lib/dakota/platform.yaml
  ${source-dir}/lib/dakota/used.json
  ${source-dir}/lib/dakota/dakota.pm
  ${source-dir}/lib/dakota/generate.pm
  ${source-dir}/lib/dakota/parse.pm
  ${source-dir}/lib/dakota/rewrite.pm
  ${source-dir}/lib/dakota/sst.pm
  ${source-dir}/lib/dakota/util.pm
)
set (install-include-files
  ${source-dir}/include/dakota-finally.h
  ${source-dir}/include/dakota-log.h
  ${source-dir}/include/dakota-object-defn.inc
  ${source-dir}/include/dakota-object.inc
  ${source-dir}/include/dakota-of.inc
  ${source-dir}/include/dakota-os.h
  ${source-dir}/include/dakota-other.inc
  ${source-dir}/include/dakota-weak-object-defn.inc
  ${source-dir}/include/dakota-weak-object.inc
  ${source-dir}/include/dakota.h
)
set (install-bin-files
  ${source-dir}/bin/dakota
  ${source-dir}/bin/dakota-parts
  ${source-dir}/bin/dakota-fixup-stderr
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
install_symlink (
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/compiler-${cxx-compiler-id}.opts
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/compiler.opts
)
install_symlink (
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/linker-${cxx-compiler-id}.opts
  ${CMAKE_INSTALL_PREFIX}/lib/dakota/linker.opts
)
