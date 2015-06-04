{
  'CXX' => [ 'clang++' ],
  'CXXFLAGS' => [ '-std=c++11' ],
  'CXX_COMPILE_FLAGS' =>     [ '--compile', '-emit-llvm' ],
  'CXX_COMPILE_PIC_FLAGS' => [ '--compile', '-emit-llvm', '-fPIC' ], # clang does not understand --PIC
  'CXX_DYNAMIC_FLAGS' =>     [ '--dynamic' ],
  'CXX_NO_WARNINGS_FLAGS' => [ '--no-warnings' ],
  'CXX_OUTPUT_FLAGS' =>      [ '--output'  ],
  'CXX_SHARED_FLAGS' =>      [ '--shared'  ],
  'CXX_WARNINGS_FLAGS' =>    [
      '-Weverything',
      '-Wno-c99-extensions', # c99 designated initializers, c99 compound literals
      '-Wno-c++98-compat-pedantic',
      '-Wno-c++98-compat',
      '-Wno-cast-align',
      '-Wno-deprecated',
      '-Wno-disabled-macro-expansion',
      '-Wno-exit-time-destructors',
      '-Wno-four-char-constants',
      '-Wno-global-constructors',
      '-Wno-multichar',
      '-Wno-old-style-cast',
      '-Wno-padded',
      ],
  'LD_SONAME_FLAGS' => [ '-install_name' ], # unique to darwin
  'O_EXT' =>  'bc',
  'SO_EXT' => 'dylib', # unique to darwin
}
