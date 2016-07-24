rootdir := ../..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 check-exe\
 clean\

target-base := exe
target := $(target-base)

all: $(target)

$(target-base).dk: 
	echo "klass hashed-table; func main() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > $@

default.project: $(target-base).dk
	$(DAKOTA-BASE) --create-project $@ --output $(target) $^

$(target): $(target-base).dk | default.project
	$(DAKOTA-BASE) --project default.project $^

no-project: $(target-base).dk
	$(DAKOTA-BASE) $^

check check-exe: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build default.project)
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build default.project)
	$(RM) $(RMFLAGS) default.project
	$(RM) $(RMFLAGS) $(target-base).dk
	$(RM) $(RMFLAGS) $(target)
