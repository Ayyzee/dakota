%.cc: %.strs
	./gen-mph-func.pl $* < $< > $*.cc

%.o: %.cc
	g++ -Wall -g3 -c -o $@ $<

all:
	./gen-mph-func.pl test < test.strs > test.h
	g++ -Wall -g3 -o exe exe.cc
	g++ -c -Wall -g3 example-out.cc

check:
	cat use-case-0.dk
	./switch-rewriting.pl use-case-0.dk
	cat use-case-1.dk
	./switch-rewriting.pl use-case-1.dk
	cat use-case-2.dk
	./switch-rewriting.pl use-case-2.dk
	cat use-case-3.dk
	./switch-rewriting.pl use-case-3.dk
	cat use-case-4.dk
	./switch-rewriting.pl use-case-4.dk
	cat example-in.cc
	./switch-rewriting.pl example-in.cc

time:
	./exe 1 > /dev/null
	./exe 0 > /dev/null

time-save:
	./exe 1 > out-1
	./exe 0 > out-0

time-noecho:
	./exe 1
	./exe 0

clean:
	rm -f exe test.{h,pl} *~ c_keywords.{cc,o} cxx_keywords.{cc,o} out-0 out-1 *.o *.s
	rm -rf exe.dSYM
