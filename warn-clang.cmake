# -*- mode: cmake -*-
set (cxx-compiler-warning-flags
  -fno-common
  --warn-no-dollar-in-identifier-extension
  --warn-no-multichar
  --warn-everything
  --warn-no-class-varargs
  --warn-non-pod-varargs # must follow --warn-no-class-varargs
  --warn-no-c++98-compat
  --warn-no-c++98-compat-pedantic
  --warn-no-c99-extensions # c99 designated initializers, c99 compound literals
  --warn-no-cast-align
  --warn-no-disabled-macro-expansion
  --warn-no-exit-time-destructors
  --warn-no-four-char-constants
  --warn-no-global-constructors
  --warn-no-old-style-cast
  --warn-no-padded
  --warn-no-unknown-warning-option
  --warn-no-unused-command-line-argument
)
