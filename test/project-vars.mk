target := $(shell $(prefix)/bin/dakota-project --var so_ext=$(so_ext) name)
prereq := $(shell $(prefix)/bin/dakota-project --var so_ext=$(so_ext) srcs)
prereq += $(shell $(prefix)/bin/dakota-project --var so_ext=$(so_ext) libs)
