rootdir := ../..

include $(rootdir)/config.mk

all: finally

finally: finally.dk
	dakota --output $@ $^

check: finally
	./finally

clean:
	rm -rf obj bin finally *~
