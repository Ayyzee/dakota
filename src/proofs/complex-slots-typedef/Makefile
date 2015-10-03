all:
	clang++ -std=c++11 -Weverything -Wno-c++98-compat --output exe-cc exe-main.cc

check: all
	./exe-cc

clean:
	rm -rf exe-cc exe-cc.dSYM *~
