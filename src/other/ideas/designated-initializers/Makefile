all: c99 c++-gnu c++-c99

c99:
	gcc --compile --language c   exe.c --output exe-$@ -std=c99

c++-c99:
	gcc --compile --language c++ exe.c --output exe-$@

c++-gnu:
	gcc --compile --language c++ exe.c --output exe-$@ --define-macro GNU_DESIGNATED_INITIALIZER

clean:
	rm -f exe-* *~
