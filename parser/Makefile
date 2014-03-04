rootdir := ..
include $(rootdir)/config.mk

export CXXFLAGS := -g3 -Wall

name :=  $(shell dk name  --var SO_EXT=$(SO_EXT))
files := $(shell dk files --var SO_EXT=$(SO_EXT))

all: $(name)

$(name): $(files)
	dakota --output $@ $^

check: all
	./check.sh sample.dk

clean:
	rm -rf $(name) obj *~
