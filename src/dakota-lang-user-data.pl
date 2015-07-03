# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{
  'kw-args-ident' => {          # variable per project (lib or exe)
    'init'   => 1,              # rhs = num-fixed args
    'append' => 2               # rhs = num-fixed args
  },
  'visibility' => {             # constant for a language
    'export'   => 1,
    'import'   => 1,
    'noexport' => 1
  },
    'array' =>            { 'open'  => { '[' => 1 },
                            'close' => { ']' => 1 } },

    'list' =>             { 'open'  => { '(' => 1 },
                            'sep'   => { ',' => 1 },
                            'close' => { ')' => 1 } },

    'initializer-list' => { 'open' =>  { '{' => 1 },
                            'sep' =>   { ',' => 1 },
                            'close' => { '}' => 1 } },

    'literal-sequence' => { 'open'  => { '#[' => 1 },
                            'sep' =>   { ',' =>  1 },
                            'close' => { ']' =>  1 } },

    'literal-assoc' =>    { 'open'  => { '#(' => 1 },
                            'op' =>    { ':' => 1 },
                            'close' => { ')' =>  1 } },

    'literal-set' =>      { 'open'  => { '#{' => 1 },
                            'sep' =>   { ',' =>  1 },
                            'close' => { '}' =>  1 } },

    'literal-table' =>    { 'open'  => { '#{' => 1 },
                            'sep' =>   { ',' =>  1 }, # comma separated list of assoc-in
                            'close' => { '}' =>  1 } },
}
