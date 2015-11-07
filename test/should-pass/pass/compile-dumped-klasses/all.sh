#!/bin/bash

set -o errexit -o nounset -o pipefail

rootdir=../../../..

$rootdir/bin/dakota-info $rootdir/lib/libdakota.dylib >      libdakota.dk
$rootdir/bin/dakota-info $rootdir/lib/libdakota-util.dylib > libdakota-util.dk

$rootdir/bin/dakota --compile --define-macro __darwin__ --output libdakota.dylib      libdakota.dk
$rootdir/bin/dakota --compile --define-macro __darwin__ --output libdakota-util.dylib $rootdir/lib/libdakota.dylib libdakota-util.dk
