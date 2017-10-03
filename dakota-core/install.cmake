set (install-lib-dakota-files
  ${root-source-dir}/lib/dakota/base.cmake
  ${root-source-dir}/lib/dakota/compiler-apple-clang.opts
  ${root-source-dir}/lib/dakota/compiler-gcc.opts
  ${root-source-dir}/lib/dakota/extra.json
  ${root-source-dir}/lib/dakota/lang-user-data.json
  ${root-source-dir}/lib/dakota/linker-apple-clang.opts
  ${root-source-dir}/lib/dakota/linker-gcc.opts
  ${root-source-dir}/lib/dakota/platform.yaml
  ${root-source-dir}/lib/dakota/used.json
  ${root-source-dir}/lib/dakota/dakota.pm
  ${root-source-dir}/lib/dakota/generate.pm
  ${root-source-dir}/lib/dakota/parse.pm
  ${root-source-dir}/lib/dakota/rewrite.pm
  ${root-source-dir}/lib/dakota/sst.pm
  ${root-source-dir}/lib/dakota/util.pm
)
set (install-include-files
  ${root-source-dir}/include/dakota-finally.h
  ${root-source-dir}/include/dakota-log.h
  ${root-source-dir}/include/dakota-object-defn.inc
  ${root-source-dir}/include/dakota-object.inc
  ${root-source-dir}/include/dakota-of.inc
  ${root-source-dir}/include/dakota-os.h
  ${root-source-dir}/include/dakota-other.inc
  ${root-source-dir}/include/dakota-weak-object-defn.inc
  ${root-source-dir}/include/dakota-weak-object.inc
  ${root-source-dir}/include/dakota.h
)
set (install-bin-files
  ${root-source-dir}/bin/dakota
  ${root-source-dir}/bin/dakota-parts
  ${root-source-dir}/bin/dakota-fixup-stderr
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
