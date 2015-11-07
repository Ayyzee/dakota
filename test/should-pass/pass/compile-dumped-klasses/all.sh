#!/bin/bash

set -o errexit -o nounset -o pipefail

rootdir=../../../..

o_ext=bc # clang only

$rootdir/bin/dakota-info $rootdir/lib/libdakota.dylib >      libdakota.dk
$rootdir/bin/dakota-info $rootdir/lib/libdakota-util.dylib > libdakota-util.dk

$rootdir/bin/dakota --compile --define-macro __darwin__ --output libdakota.$o_ext      libdakota.dk
$rootdir/bin/dakota --compile --define-macro __darwin__ --output libdakota-util.$o_ext libdakota-util.dk $rootdir/lib/libdakota.dylib
