#!/bin/bash
set -o errexit -o nounset -o pipefail

so_ext=dylib
LD_NAME_FLAG=-install_name
CXX_SHARED_FLAGS="-dynamiclib"
CXX_DYNAMIC_FLAGS="-dynamiclib"
