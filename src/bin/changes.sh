#!/bin/sh -u

perl -p -i -0777 -e 's|(\w+?)_(hxx_str_ref)|\$files{$1}{$2}|gcm' bin/dakota.pm
perl -p -i -0777 -e 's|(\w+?)_(cxx_str_ref)|\$files{$1}{$2}|gcm' bin/dakota.pm

perl -p -i -0777 -e 's|\$(\w+?)_(hxx_str)|\$files{$1}{$2}|gcm' bin/dakota.pm
perl -p -i -0777 -e 's|\$(\w+?)_(cxx_str)|\$files{$1}{$2}|gcm' bin/dakota.pm


#perl -p -i -0777 -e 's|(\w+?_decl_str_ref)|\$files\{$1\}|gcm' bin/dakota.pm
#perl -p -i -0777 -e 's|(\w+?_defn_str_ref)|\$files\{$1\}|gcm' bin/dakota.pm

#perl -p -i -0777 -e 's|\$(\w+?_decl_str)|\$files\{$1\}|gcm' bin/dakota.pm
#perl -p -i -0777 -e 's|\$(\w+?_defn_str)|\$files\{$1\}|gcm' bin/dakota.pm
