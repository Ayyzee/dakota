set (install-lib-dakota-files
  ${dakota-lang-source-dir}/lib/dakota/base.cmake
  ${dakota-lang-source-dir}/lib/dakota/compiler-apple-clang.opts
  ${dakota-lang-source-dir}/lib/dakota/compiler-gcc.opts
  ${dakota-lang-source-dir}/lib/dakota/extra.json
  ${dakota-lang-source-dir}/lib/dakota/lang-user-data.json
  ${dakota-lang-source-dir}/lib/dakota/linker-apple-clang.opts
  ${dakota-lang-source-dir}/lib/dakota/linker-gcc.opts
  ${dakota-lang-source-dir}/lib/dakota/platform.yaml
  ${dakota-lang-source-dir}/lib/dakota/used.json
  ${dakota-lang-source-dir}/lib/dakota/dakota.pm
  ${dakota-lang-source-dir}/lib/dakota/generate.pm
  ${dakota-lang-source-dir}/lib/dakota/parse.pm
  ${dakota-lang-source-dir}/lib/dakota/rewrite.pm
  ${dakota-lang-source-dir}/lib/dakota/sst.pm
  ${dakota-lang-source-dir}/lib/dakota/util.pm
)
set (install-include-files
  ${dakota-lang-source-dir}/include/dakota-finally.h
  ${dakota-lang-source-dir}/include/dakota-log.h
  ${dakota-lang-source-dir}/include/dakota-object-defn.inc
  ${dakota-lang-source-dir}/include/dakota-object.inc
  ${dakota-lang-source-dir}/include/dakota-of.inc
  ${dakota-lang-source-dir}/include/dakota-os.h
  ${dakota-lang-source-dir}/include/dakota-other.inc
  ${dakota-lang-source-dir}/include/dakota-weak-object-defn.inc
  ${dakota-lang-source-dir}/include/dakota-weak-object.inc
  ${dakota-lang-source-dir}/include/dakota.h
)
set (install-bin-files
  ${dakota-lang-source-dir}/bin/dakota
  ${dakota-lang-source-dir}/bin/dakota-parts
  ${dakota-lang-source-dir}/bin/dakota-fixup-stderr
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
