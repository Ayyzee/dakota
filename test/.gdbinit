set annotate 1
set env DYLD_BIND_AT_LAUNCH
file exe
directory ../../../src
directory ../../../src/obj
directory ../../../src/obj/lib
source ~/.dakota/.gdbinit
run
