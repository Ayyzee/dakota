#!/bin/bash

#perl -pi.bak -e 'BEGIN { undef $/; } s/\s*?(\s?\/\/.*)?\r?\n\s*{/ {\1/g; s/}(\s?\/\/.*)?\r?\n\s*else\b(.*)/} else\2\1/g;'

#files=`echo ../lib/*.pm  ../bin/*.pl ../bin/{dakota,dk}`
files=$(find .. -name "*.dk")
#wc -l $files

$main::list_in = qr{
                     (?:
                       (?> [^()]+ )         # Non-parens without backtracking
                     |
                       (??{ $main::list }) # Group with matching parens
                     )*
                 }x;

perl -p -i -e 'BEGIN { undef $/; } s/(if|for|while)\s*\($main::list_in\)\s*\n\s*\n/$1 \($2\) \{/gm' $files



#perl -p -i -e 'BEGIN { undef $/; } s/\)\s*?\n+.+?\{\s*?\n+/\) \{\n/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/\}\s*?\n+\s*else\s*?\n*\s*\{\s*\n/\} else \{\n/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/\n(\s*)\}\s*?\n+\s*else-if/\n$1\} else-if/gm' $files

#perl -p -i -e 'BEGIN { undef $/; } s/\}\s*(else|else-if)\s*\((.*?)\)\s*\n(\s*)(\{\s*[^\s]+\s*\})/\}\n$3$1 ($2)\n$3$4/gm' $files

#perl -p -i -e 'BEGIN { undef $/; } s/\n\s+\n/\n\n/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/=\s*\n+\s*\{/= \{/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/\n+sub\s+((\w+::)*?\w+(\(\))?)\s*\n*\s*\{\n*/\nsub $1 \{\n/gm' $files

#perl -p -i -e 'BEGIN { undef $/; } s/\@_;\s*\n\s*\n/\@_;\n/gm' $files
#perl -p -i -e 'BEGIN { undef $/; } s/\n\s*\n(\s*)return\s+/\n$1return /gm' $files

#wc -l $files

# fix these by hand
# {} else {
# =>
# {}
# else {

# #elsif (!&has_exported_slots($klass_scope) && !&is_exported($klass_scope)) {
