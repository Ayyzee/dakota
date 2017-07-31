pushd $INSTALL_PREFIX/lib/dakota
ln -fs compiler-$compiler.cmake compiler.cmake
ln -fs compiler-$compiler.opts  compiler.opts
ln -fs compiler-command-line-$compiler.json compiler-command-line.json
ln -fs platform-$platform.json platform.json
popd

