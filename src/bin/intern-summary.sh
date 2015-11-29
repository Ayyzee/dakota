#!/bin/bash

set -o errexit -o nounset -o pipefail

#grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | sort -u
#grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | sort -u

grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | sort -u
echo
grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep -v "symbol-t " | sort -u

#exit 0

grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | sort    > out.txt
grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | sort -u > out-uniqued.txt
#diff out.txt out-uniqued.txt || true

echo

grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep -v "symbol-t " | sort    > out-util.txt
grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep -v "symbol-t " | sort -u > out-util-uniqued.txt
#diff out-util.txt out-util-uniqued.txt || true

grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep    "symbol-t " | wc -l
grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | wc -l
grep dk-intern obj/rt/dakota/lib/libdakota.dkcc | tr -s " " | grep -v "symbol-t " | sort -u | wc -l

echo

grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep    "symbol-t " | wc -l
grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep -v "symbol-t " | wc -l
grep dk-intern obj/rt/dakota/lib/libdakota-util.dkcc | tr -s " " | grep -v "symbol-t " | sort -u | wc -l
