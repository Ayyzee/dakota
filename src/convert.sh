#!/bin/bash

#files=$(find .. -name "*.dk")

#perl -p -i -e 's/mode: C\+\+/mode: Dakota/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/2007, 2008, 2009/2007 - 2015/gm' $files

# dk_ext
# dk_ext =
# ctlg_ext
# pl_ext
# pm_ext
# rep_ext
# json_ext

#perl -p -i -e 's/my\s*\$dk_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/my\s*\$ctlg_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/my\s*\$pl_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/my\s*\$pm_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/my\s*\$rep_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/my\s*\$json_ext\s*=.+?;\n//g' ../lib/dakota/*.pm ../bin/dakota

#perl -p -i -e 's/\$dk_ext\b/dk/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\$ctlg_ext\b/ctlg/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\$pl_ext\b/pl/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\$pm_ext\b/pm/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\$rep_ext\b/rep/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\$json_ext\b/json/g' ../lib/dakota/*.pm ../bin/dakota

#perl -p -i -e 's/my\s*dk\s*=.+?;//g' ../lib/dakota/*.pm ../bin/dakota

# rt_obj\b
# _obj_
# obj_from
# \bobj_path
# \bobj_cmd\b
# obj_info

#perl -p -i -e 's/rt_obj/rt_o/g' ../lib/dakota/*.pm
#perl -p -i -e 's/_obj_/_o_/g' ../lib/dakota/*.pm
#perl -p -i -e 's/obj_fromj/o_from/g' ../lib/dakota/*.pm
#perl -p -i -e 's/obj_path/o_path/g' ../lib/dakota/*.pm
#perl -p -i -e 's/obj_cmd/o_cmd/g' ../lib/dakota/*.pm
#perl -p -i -e 's/obj_info/o_info/g' ../lib/dakota/*.pm

#perl -p -i -e 's/\b_(add_first)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\b_(add_last)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\b_(first)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\b_(last)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\b_(remove_first)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota
#perl -p -i -e 's/\b_(remove_last)\b/$1/g' ../lib/dakota/*.pm ../bin/dakota

#egrep "push|pop|shift|unshift" ../lib/dakota/*.pm ../bin/dakota

#perl -p -i -e 's|\brealloc\(\s*(.+?)\s*,\s*(.+?)\s*\);|alloc\($2, $1\)|g' *.dk *.cc

#perl -p -i -e 's|\brealloc\(\s*(.+?)\s*,\s*(.+?)\s*\);|dkt::alloc\($2, $1\);|g' *.dk *.cc
#perl -p -i -e 's|\bfree\b|dkt::dealloc|g' *.dk *.cc
#perl -p -i -e 's|\bmalloc\b|dkt::alloc|g' *.dk *.cc

#cpp=define|elif|else|endif|error|if|ifdef|ifndef|include|line|pragma|undef|warning


#perl -p -i -e 's/\$(define|elif|else|endif|error|if|ifdef|ifndef|include|line|pragma|undef|warning)/#$1/g' *.dk

#perl -p -i -e 's/#/\$/g' *.dk

#for directive in $cpp; do
#    perl -p -i -e 's/\$directive/#$directive/g' *.dk
#done

#perl -p -i -e 's/dk::(parse)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(generate_cc_footer_klass)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(generate_cc_footer)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(generate_kw_args_method_defns)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(generate_imported_klasses_info)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(generate_dk_cc)/dk_$1/g' ../lib/dakota/*.pm
#perl -p -i -e 's/dk::(klass_names_from_file)/dk_$1/g' ../lib/dakota/*.pm

#perl -p -i -e 's/^\s*include\s+(.+?)\s*;\s*\n/#include $1\n/gm' *.dk

#perl -p -i -e 'undef $/; s/(klass|trait)\s+([\w:-]+)\s*\{/$1 $2 \{/gms' *.dk
#perl -p -i -e 'undef $/; s/^(\s+slots)\s*\n\s+\{/$1 \{/gms' *.dk

#perl -p -i -e 's/^(use Carp)/#$1/gm' ../lib/dakota/*.pm
#perl -p -i -e 's/^(\$SIG)/#$1/gm' ../lib/dakota/*.pm

#perl -p -i -e 's/dkt-(klass|superklass|name)\b/$1-of/g' *.dk ../lib/dakota/*.pm
#perl -p -i -e 's/dkt_(klass|superklass|name)\b/$1_of/g' ../include/*.hh

#perl -p -i -e 's/dk::(klass|superklass|name)\b/$1-of/g' ../test/should-pass/pass/*/*.dk
#perl -p -i -e 's/dk::(klass|superklass|name)\b/$1-of/g' ../test/should-fail/*/*.dk
#perl -p -i -e 's/dk::(klass|superklass|name)\b/$1-of/g' ../test/should-pass/fail/*/*.dk

#perl -p -i -e 'undef $/; s/(init\(object-t self,)[\s\n]+(slots-t)\s+(slots)\b/$1 $2 $3/gs' *.dk

# method alias(add-last) object-t push(object-t self, object-t element);
# =>
# method push() => add-last();

git diff .. > /tmp/git-diff-$$.patch
git checkout ..
perl -p -i -e 'undef $/; s/(\s+met)(hod\s+)alias\((.+?)\).*?\s([a-zA-Z0-9-]+)\(.*?;/$1+$2$4() => $3();/gs' deque.dk vector.dk
perl -p -i -e 'undef $/; s/(\s+method\s+)(.+?)\s*([a-zA-Z0-9-]+(\!|\?)?\(object-t.*?\)\s*)(\;|\{)/$1$3 -> $2$5/gs' *.dk
perl -p -i -e 's/met\+hod/method/g' *.dk
perl -p -i -e 's/\)  -> /\) -> /g' *.dk
perl -p -i -e 's/-t\{/-t \{/g' *.dk
git diff

