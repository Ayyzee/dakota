set (install-lib-dakota-files
  ../lib/dakota/compiler-command-line-clang.json
  ../lib/dakota/compiler-command-line-gcc.json
  ../lib/dakota/extra.json
  ../lib/dakota/lang-user-data.json
  ../lib/dakota/platform-darwin.json
  ../lib/dakota/platform-linux.json
  ../lib/dakota/used.json
  ../lib/dakota/dakota.pm
  ../lib/dakota/generate.pm
  ../lib/dakota/parse.pm
  ../lib/dakota/rewrite.pm
  ../lib/dakota/sst.pm
  ../lib/dakota/util.pm
)
set (install-include-files
  ../include/dakota-finally.h
  ../include/dakota-log.h
  ../include/dakota-object-defn.inc
  ../include/dakota-object.inc
  ../include/dakota-of.inc
  ../include/dakota-os.h
  ../include/dakota-other.inc
  ../include/dakota-weak-object-defn.inc
  ../include/dakota-weak-object.inc
  ../include/dakota.h
)
set (install-bin-files
  ../bin/dakota
  ../bin/dakota-build
  ../bin/dakota-build2cmake
  ../bin/dakota-build2mk
  ../bin/dakota-build2project
  ../bin/dakota-fixup-stderr
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
