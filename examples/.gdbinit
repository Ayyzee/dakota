set annotate 1
set env DYLD_BIND_AT_LAUNCH
file exe
break main
source ~/.dakota.d/.gdbinit
run
