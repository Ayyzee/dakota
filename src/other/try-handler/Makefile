export CXXFLAGS := -Wall -g3 -Wextra -I.

all:
	dakota --output exe exe.dk try-catch-rewrite.dk handler-context.dk exception-handler.dk

throws:
	./gen-throw-examples.pl > out1
	./gen-throw-examples.pl | ./rewrite-throws.pl > out2
	diff --minimal out1 out2

cxx:
	g++ -c -Wall -g3 cxx-exception-syntax-examples.cc

check: all
	./exe
clean:
	rm -rf exe obj cxx-exception-syntax-examples.o *~
