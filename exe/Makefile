rootdir := ..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -rf

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 clean\
 target\

target := exe
target.project := $(target).project

all: $(target)

$(target):
	echo "func main() -> int-t { klass hashed-table; object-t o = make(hashed-table::klass); USE(o); return 0; }" > $(target).dk
	$(DAKOTA-BASE) --create-project --output $(target) $(target).dk
	$(DAKOTA-BASE) --project $(target.project) $(target).dk

check: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build $(target.project))
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build $(target.project))
	$(RM) $(RMFLAGS) $(target.project)
	$(RM) $(RMFLAGS) $(target).dk
