all:
	g++ -Wall -g3 -o ./anon-structs anon-structs.cc
	g++ -c -Wall -g3 tuples.cc

wish:
	gcc -x c -std=c99 -DSTD_C99=1 -Wall -g3 wish.cc; exit 0
	g++ -Wall -g3 wish.cc
check:
	./anon-structs

clean:
	rm -f ./anon-structs tuples.o *~
