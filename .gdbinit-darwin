set annotate 1
set env DYLD_BIND_AT_LAUNCH
file bin/dakota-info
catch throw
break main
source ~/.dakota.d/.gdbinit
run lib/libdakota.dylib lib/libdakota-util.dylib
