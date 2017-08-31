set (install-lib-dakota-files
  ${root-dir}/lib/dakota/base.cmake
  ${root-dir}/lib/dakota/compiler-apple-clang.opts
  ${root-dir}/lib/dakota/compiler-gcc.opts
  ${root-dir}/lib/dakota/extra.json
  ${root-dir}/lib/dakota/lang-user-data.json
  ${root-dir}/lib/dakota/linker-apple-clang.opts
  ${root-dir}/lib/dakota/linker-gcc.opts
  ${root-dir}/lib/dakota/platform.yaml
  ${root-dir}/lib/dakota/used.json
  ${root-dir}/lib/dakota/dakota.pm
  ${root-dir}/lib/dakota/generate.pm
  ${root-dir}/lib/dakota/parse.pm
  ${root-dir}/lib/dakota/rewrite.pm
  ${root-dir}/lib/dakota/sst.pm
  ${root-dir}/lib/dakota/util.pm
)
set (install-include-files
  ${root-dir}/include/dakota-finally.h
  ${root-dir}/include/dakota-log.h
  ${root-dir}/include/dakota-object-defn.inc
  ${root-dir}/include/dakota-object.inc
  ${root-dir}/include/dakota-of.inc
  ${root-dir}/include/dakota-os.h
  ${root-dir}/include/dakota-other.inc
  ${root-dir}/include/dakota-weak-object-defn.inc
  ${root-dir}/include/dakota-weak-object.inc
  ${root-dir}/include/dakota.h
)
set (install-bin-files
  ${root-dir}/bin/dakota
  ${root-dir}/bin/dakota-parts
  ${root-dir}/bin/dakota-fixup-stderr
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
