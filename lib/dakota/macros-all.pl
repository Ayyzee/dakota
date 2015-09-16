# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{
  'literal-pair' => { # $( key : expr )
    'rules' => [ {
      'pattern'  => [        '#(',                       ')' ],
      'template' => [ 'make', '(', 'LITERAL-PAIR-KLASS', ')' ]
    }, {
      'pattern'  => [        '#(',                                         '?symbol', ':',                               '?expr',      ')' ],
      'template' => [ 'make', '(', 'LITERAL-PAIR-KLASS', ',', '#key', ':', '?symbol', ',',  '#element', ':', 'box', '(', '?expr', ')', ')' ]
    } ],
  },
  'literal-sequence' => { # $[ expr, ... ]
    'rules' => [ {
      'pattern'  => [ '#[',   ']'                                ],
      'template' => [ 'make', '(', 'LITERAL-SEQUENCE-KLASS', ')' ]
    } ],
  },
  'literal-set' => { # ${ expr, ... }
    'rules' => [ {
      'pattern'  => [ '#{',    ',', '}'                      ],
      'template' => [ 'make', '(',  'LITERAL-SET-KLASS', ')' ]
    } ],
  },
  'literal-table' => { # ${ ?symbol : ?expr , ... }
    'rules' => [ {
      'pattern'  => [ '#{', '}'                               ],
      'template' => [ 'make', '(', 'LITERAL-TABLE-KLASS', ')' ]
    }, {
      'pattern'  => [ '#{', ':', '}'                         ],
      'template' => [ 'make', '(', 'LITERAL-TABLE-KLASS', ')' ]
    }, {
      'pattern'  => [                                                                                                '#{',                   '?literal-table-pair-in-list', '}'      ],
      'template' => [ 'make', '(', 'LITERAL-TABLE-KLASS', ',', '#items', ':', 'cast', '(', 'object-t', '[', ']', ')', '{', 'NULL-PAIR', ',', '?literal-table-pair-in-list', '}', ')' ]
    } ],
  },
  'literal-table-pair' => {
    'rules' => [ {
      'pattern'  => [ 'NULL-PAIR', ',',       '?literal-pair-in'                        ],
      'template' => [                   '#(', '?literal-pair-in', ')', ',', 'NULL-PAIR' ]
    } ],
  },
  'include-stmt' => {
    'rules' => [ {
      'pattern'  => [      'include', '?dquote-str', ';' ],
      'template' => [ '#', 'include', '?dquote-str'      ]
    } ],
  },
  'klass-or-trait-decl' => {
    'rules' => [ {
      'pattern'  => [ '?/(klass|trait)/', '?ident', ';' ],
      'template' => []
    } ],
  },
  'klass-or-trait-defn' => {
    'rules' => [ {
      'pattern'  => [ '?/(klass|trait)/', '?ident', '{' ],
      'template' => [ 'namespace',        '?ident', '{' ]
    } ],
  },
  'superklass-decl' => {
    'rules' => [ {
      'pattern'  => [ 'superklass', '?ident', ';' ],
      'template' => []
    } ],
  },
  'slots-defn' => {
    'rules' => [ {
      'pattern'  => [ 'slots',             '?block',     ],
      'template' => [ 'struct', 'slots-t', '?block', ';' ]
    } ],
  },
  'keyword-args-defn' => {
    'rules' => [ {
      'pattern'  => [ '?type', '?/([a-zA-Z0-9-]+\??)/', ':', '?list-member', ],
      'template' => [ '?type', '?2',                                         ]
    } ],
  },
  'keyword-args-use' => {
    'rules' => [ {
      'pattern'  => [ 'NULL-KEYWORD', ',',                               '?/\$([a-zA-Z0-9-]+\??)/', ':', '?list-member'                      ],
      'template' => [                      '__keyword', '::', '_', '##', '?3',                      ',', '?list-member', ',', 'NULL-KEYWORD' ]
    }, {
      'pattern'  => [                 ',',                               '?/\$([a-zA-Z0-9-]+\??)/', ':', '?list-member'                      ], # leading comma is required
      'template' => [                 ',', '__keyword', '::', '_', '##', '?2',                      ',', '?list-member', ',', 'NULL-KEYWORD' ]  # leading comma is required
    } ],
  },
  'symbol' => {
    'rules' => [ {
      'pattern'  => [                               '?/\$([a-zA-Z0-9-]+\??)/' ],
      'template' => [ '__symbol',  '::', '_', '##', '?1'                      ]
    } ],
  },
  'keyword-args-wrap' => {
    'rules' => [ {
      'pattern'  => [ 'dk', '?/(::?)/', '?kw-args-ident-1', '(', '?list-member',                 ')' ],
      'template' => [ 'dk', '?/(::?)/', '?kw-args-ident-1', '(', '?list-member', ',', 'NULLPTR', ')' ]
    }, {
      'pattern'  => [ 'dk', '?/(::?)/', '?kw-args-ident-2', '(', '?list-member', ',', '?list-member',                 ')' ],
      'template' => [ 'dk', '?/(::?)/', '?kw-args-ident-2', '(', '?list-member', ',', '?list-member', ',', 'NULLPTR', ')' ]
    } ],
  },
  'method-alias' => {
    'rules' => [ {
      'pattern'  => [ 'method', 'alias', '?list' ],
      'template' => [ 'method'                   ]
      } ],
  },
  'va-method-defn' => {
    'rules' => [ {
      'pattern'  => [                         '?visibility', 'method', '?type', 'va', '?/(::?)/', '?ident', '?list', '?block'      ],
      'template' => [ 'namespace', 'va', '{', '?visibility', 'method', '?type',                   '?ident', '?list', '?block', '}' ]
    }, {
      'pattern'  => [                                        'method', '?type', 'va', '?/(::?)/', '?ident', '?list', '?block'      ],
      'template' => [ 'namespace', 'va', '{',                'method', '?type',                   '?ident', '?list', '?block', '}' ]
    } ],
  },
  'export-method' => {
    'rules' => [ {
      'pattern'  => [ 'export', 'method', '?type', '?ident', '?list' ],
      'template' => [ 'extern',           '?type', '?ident', '?list' ]
    } ],
  },
  'method' => {
    'rules' => [ {
      'pattern'  => [ 'method', '?type', '?ident', '?list' ],
      'template' => [ 'static', '?type', '?ident', '?list' ]
    } ],
  },
  'super' => {
    'rules' => [ { # try to merge both super rules (make the va: optional)
      'pattern'  => [ 'dk', '?/(::?)/',                   '?ident', '(', 'super',                                           '?list-member-term' ],
      'template' => [ 'dk', '?/(::?)/',                   '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
    }, {   # for the very rare case that a user calls the dk:va: generic
      'pattern'  => [ 'dk', '?/(::?)/', 'va', '?/(::?)/', '?ident', '(', 'super',                                           '?list-member-term' ],
      'template' => [ 'dk', '?/(::?)/', 'va', '?4',       '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
    } ],
  },
  'slot-access' => {
    'rules' => [ {
      'pattern'  => [               'self',      '.',  '?ident' ],
      'template' => [ 'unbox', '(', 'self', ')', '->', '?ident' ]
    } ],
  },
  'explicit-box-literal' => {
    'rules' => [ {
      'pattern'  => [ '?ident', '?/(::?)/', 'box', '(',                 '{', '?block-in', '}',      ')'  ],
      'template' => [ '?ident', '?/(::?)/', 'box', '?4', '?ident', '(', '{', '?block-in', '}', ')', '?8' ]
    } ],
  },
  'construct-klass-slots-literal' => {
    'rules' => [ { # ?ident is a klass-name
      'pattern'  => [ '?ident',                        '(', '{', '?block-in', '}', ')' ],
      'template' => [ '?ident',     '::', 'construct', '(',      '?block-in',      ')' ]
        #'template' => [ 'cast', '(', '?{ident}-t', ')',      '{', '?block-in', '}'      ]
        #'template' => [ '?{ident}-t',                   '(',      '?block-in',      ')' ]
      } ],
  },
  # throw "..."
  # throw $foo
  # throw $"..." ;
  # throw $[...] ;
  # throw ${...} ;
  # throw box(...) ;
  # throw foo:box(...) ;
  # throw make(...) ;
  # throw klass ;
  # throw self ;
  'throw-make-or-box' => {
    'rules' => [ {
      'pattern'  => [ 'throw',                                       '?/(make|box)/', '(',  '?list-in', ')'       ],
      'template' => [ 'throw', 'dkt-capture-current-exception', '(', '?/(make|box)/', '?3', '?list-in', '?5', ')' ]
    } ],
  },
  'throw-make-or-box-parens' => {
    'rules' => [ {
      'pattern'  => [ 'throw', '(',                                        '?/(make|box)/', '(',  '?list-in', ')',  ')'       ],
      'template' => [ 'throw', '?2', 'dkt-capture-current-exception', '(', '?/(make|box)/', '?4', '?list-in', '?6', '?7', ')' ]
    } ],
  },
  'make' => {
    'disabled' => 1,
    'rules' => [ {
      'pattern'  => [ 'make',                                       '(',  '?list-member'      ],
      'template' => [ 'dk', '::', 'init', '(', 'dk', '::', 'alloc', '?2', '?list-member', ')' ]
    } ],
  },
  'export-enum' => {
    'rules' => [ {
      'pattern'  => [ 'export', 'enum', '?type-ident', '?block' ],
      'template' => []
      } ],
  },

  # ?(optional ?[ keys elements ] )
  # ?(optional not )
  # ?(optional va : )
  # ?(not ?look-ahead xx yy )
  # ?(not ?look-behind xx yy )

  # if|while (e [not] in [keys|elements] tbl)
  # if|while (e [not] in tbl)
  'if-or-while-in-iterable' => { # optional 'not' and optional 'keys|elements'
    'rules' => [ {
      'pattern'  => [ '?/(if|while)/', '(',  '?ident',   'in',                  '?/(keys|elements)/',      '?list-member',      ')'  ],
      'template' => [ '?/(if|while)/', '?2', '?ident',   'in',      'dk', '::', '?/(keys|elements)/', '(', '?list-member', ')', '?7' ]
    }, {
      'pattern'  => [ '?/(if|while)/', '(',  '?ident',   'in',      '?list-member',                                             ')'  ],
      'template' => [ '?/(if|while)/', '?2', 'dk', '::', 'in', '(', '?list-member', ',', '?ident', ')',                         '?6' ]
    } ],
  },
  'if-or-while' => { # this could just have patterns (a missing template implies echoing the pattern match)
    'rules' => [ {
      'pattern'  => [ 'if' ],
      'template' => [ 'if' ],
    }, {
      'pattern'  => [ 'while' ],
      'template' => [ 'while' ],
    } ],
  },
  # for (object-t e [not] in [keys|elements] tbl)
  # for (object-t e [not] in seq)
  'for-in-iterable' => {
    'rules' => [ {
      'pattern'  => [ 'for', '(',  'object-t', '?ident', 'in',             '?/(keys|elements)/',      '?list-member',      ')'  ],
      'template' => [ 'for', '?2', 'object-t', '?ident', 'in', 'dk', '::', '?/(keys|elements)/', '(', '?list-member', ')', '?8' ]
    }, {
      'pattern'  => [ 'for', '(',  'object-t', '?ident', 'in', '?list-member', ')' ],
      'template' => [ 'for', '?2', 'object-t', '_iterator_', '=', 'dk', '::', 'forward-iterator', '(', '?list-member', ')', ';',
                      'object-t', '?ident', '=', 'dk', '::', 'next', '(', '_iterator_', ')', ';', '?7' ]
    } ],
  },

  # default values
  # optional sequence of tokens (more than one)
  # resolve concatenation and stringification
  # comments
  # how about include <...> ;
  # how about trait ?list-in ;

  # only in template: ?(my-fuction some-pattern-var) to do some textual transformation (also passes in macro or macro/sub-macro name and rule number)

  # $()   pair/list
  # $[]   vector
  # ${}   set
  # ${:} table

  # ?{ident}-t ?ident = box({ ... })
  # =>
  # ?{ident}-t ?ident = ?{ident}:box({ ... })
  # or
  # ?type ?ident = box({ ... })
  # =>
  # ?type ?ident = box(cast(?type){ ... })

  # foo:slots-t* slt = unbox(bar)
  # =>
  # foo:slots-t* slt = foo:unbox(bar)

  # foo:slots-t& slt = *unbox(bar)
  # =>
  # foo:slots-t& slt = *foo:unbox(bar)

  # foo-t* slt = unbox(bar)
  # =>
  # foo-t* slt = foo:unbox(bar)

  # foo-t& slt = *unbox(bar)
  # =>
  # foo-t& slt = *foo:unbox(bar)
}
