rn__mph_00_args := '{ "name" => "rn::mph_00", "use-multiple-returns" => 0, "should-reverse-order" => 1, "fail" => 0, "base" => 1 }'
mph_00_args := '{ "name" => "mph_00", "use-multiple-returns" => 0, "should-reverse-order" => 1, "fail" => 0, "base" => 1 }'
words_args := '{ "name" => "words", "use-multiple-returns" => 0, "should-reverse-order" => 1, "fail" => 0, "base" => 1 }'

all:
	${MAKE} rn--mph_00
	${MAKE} mph_00
	${MAKE} combined
	g++ -O3 -Wall -o exe exe.cc rn--mph_00.cc
	g++ -c -O3 -Wall -o example-out.o example-out.cc

words:
	./gen-mph-func.pl ${words_args} < /usr/share/dict/words > words.cc
	g++ -c -O3 -Wall -o words.o words.cc
	g++ -S -O3 -Wall -o words.s words.cc
	wc words.s

syntax:
	gcc -c -Wall -O3 -x c   mph.h
	g++ -c -Wall -O3 -x c++ mph.h

diff:
	cp rn--mph_00.h /tmp
	perl -p -i -e 's/RN__//g' /tmp/rn--mph_00.h
	diff --ignore-all-space mph_00.h /tmp/rn--mph_00.h || true

rn--mph_00:
	./gen-mph-func.pl ${rn__mph_00_args} < rn--mph_00.strs > rn--mph_00.cc
	g++ -c -O3 -Wall -o rn--mph_00.o rn--mph_00.cc
	g++ -S -O3 -Wall -o rn--mph_00.s rn--mph_00.cc
	wc rn--mph_00.s

mph_00:
	./gen-mph-func.pl ${mph_00_args} < rn--mph_00.strs > mph_00.c
	gcc -c -O3 -Wall -o mph_00.o mph_00.c
	gcc -S -O3 -Wall -o mph_00.s mph_00.c
	wc mph_00.s

combined:
	cat mph_00.c rn--mph_00.cc > combined.cc
	g++ -c -x c++ -O3 -Wall -o combined.o combined.cc

overview: rn--mph_00
	grep "case NUL" mph_00.c | perl -pe 's/^\s*//'
	grep "case NUL" rn--mph_00.cc | perl -pe 's/^\s*//'

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
	g++ -O3 -Wall -o time-mph_00 time-mph_00.cc rn--mph_00.cc
	./time-mph_00
	./exe 1 < rn--mph_00-test.strs > /dev/null
	./exe 0 < rn--mph_00-test.strs > /dev/null

time-save:
	./exe 1 < rn--mph_00-test.strs > out-1
	./exe 0 < rn--mph_00-test.strs > out-0

time-noecho:
	./exe 1
	./exe 0

clean:
	rm -f exe rn--mph_00.{pl,h,cc} mph_00.{pl,h,c} *~ c_keywords.{cc,o} cxx_keywords.{cc,o} out-0 out-1 *.o *.s combined.* time-mph_00
	rm -rf *.dSYM *.gch
