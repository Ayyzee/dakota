{
  'O_EXT' =>  'bc',
  'SO_EXT' => 'dylib', # unique to darwin
  'LD_SONAME_FLAGS' => '-install_name', # unique to darwin

  'CXX' =>            'clang++',
  'CXX_COMPILE_PIC_FLAGS' =>     '--compile -fPIC -emit-llvm',
  'CXX_COMPILE_FLAGS' =>         '--compile -emit-llvm',

  'CXX_WARNINGS_FLAGS' =>    "\
 -Wno-c++98-compat-pedantic\
 -Wno-c++98-compat\
 -Wno-cast-align\
 -Wno-deprecated\
 -Wno-disabled-macro-expansion\
 -Wno-exit-time-destructors\
 -Wno-four-char-constants\
 -Wno-global-constructors\
 -Wno-multichar\
 -Wno-old-style-cast\
 -Wno-padded\
"
}
