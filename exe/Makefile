rootdir := ..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 clean\

target := exe
target.project := $(target).project

all: $(target)

$(target).dk: 
	echo "klass hashed-table; func main() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > $@

$(target.project):
	$(DAKOTA-BASE) --create-project $@ --output $(target) $(target).dk

$(target): $(target).dk $(target.project)
	$(DAKOTA-BASE) --project $(target.project) $(target).dk

check: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build $(target.project))
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build $(target.project))
	$(RM) $(RMFLAGS) $(target.project)
	$(RM) $(RMFLAGS) $(target).dk
