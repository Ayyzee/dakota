#!/bin/bash

set -o nounset -o errexit

./make-file-dependency-graph.pl dummy-project.rep > dummy-project.dot
cat dummy-project.mk
open dummy-project.dot
