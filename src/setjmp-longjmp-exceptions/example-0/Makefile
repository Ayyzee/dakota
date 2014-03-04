export CXXFLAGS := -Wall -g3 -Wextra

all:
	DK_USE_COMPOUND_LITERALS=1 dakota --output exe exe.dk try-catch-rewrite.dk ../exception-context.dk ../exception-handler.dk ../xjmp-buf.dk ../xsigjmp-buf.dk

check: all
	./exe
clean:
	rm -rf exe obj *~
