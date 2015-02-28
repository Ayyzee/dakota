# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{
  'include-stmt' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [      'include', '?dquote-str', ';' ],
      'template' => [ '#', 'include', '?dquote-str'      ]
    } ],
  },
  'klass-or-trait-decl' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ '?/(klass|trait)/', '?ident', ';' ],
      'template' => []
    } ],
  },
  'klass-or-trait-defn' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ '?/(klass|trait)/', '?ident', '{' ],
      'template' => [ 'namespace',      '?ident', '{' ]
    } ],
  },
  'superklass-decl' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'superklass', '?ident', ';' ],
      'template' => []
    } ],
  },
  'slots-defn' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'slots',             '?block',     ],
      'template' => [ 'struct', 'slots-t', '?block', ';' ]
    } ],
  },
  'keyword-args-defn' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ '?type', '?ident', '=>', '?list-member', ],
      'template' => [ '?type', '?ident',                       ]
    } ],
  },
  'keyword-args-use' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'NULL-KEYWORD', ',',                    '?symbol', '=>', '?list-member'                       ],
      'template' => [                      '__keyword', '::', '?symbol', ',',  '?list-member', ',', 'NULL-KEYWORD'  ]
    }, {
      'pattern'  => [                 ',',                    '?symbol', '=>', '?list-member'                       ],
      'template' => [                 ',', '__keyword', '::', '?symbol', ',',  '?list-member', ',', 'NULL-KEYWORD'  ]
    } ],
  },
  'keyword-args-wrap' => {
    'before' => [ 'keyword-args-use', 'super' ],
    'rules' => [ {
      'pattern'  => [ 'dk', '?/(::?)/', '?kw-args-ident-1', '(', '?list-member',                      ')' ],
      'template' => [ 'dk', '?/(::?)/', '?kw-args-ident-1', '(', '?list-member', ',', 'NULL-KEYWORD', ')' ]
    }, {
      'pattern'  => [ 'dk', '?/(::?)/', '?kw-args-ident-2', '(', '?list-member', ',', '?list-member',                      ')' ],
      'template' => [ 'dk', '?/(::?)/', '?kw-args-ident-2', '(', '?5',           ',', '?list-member', ',', 'NULL-KEYWORD', ')' ] # hackhack
    } ],
  },
  'method-alias' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'method', 'alias', '?list' ],
      'template' => [ 'method'                   ]
      } ],
  },
  'va-method-defn' => {
    'before' => [ 'method-alias' ],
    'rules' => [ {
      'pattern'  => [                         '?visibility', 'method', '?type', 'va', '?/(::?)/', '?ident', '?list', '?block'      ],
      'template' => [ 'namespace', 'va', '{', '?visibility', 'method', '?type',             '?ident', '?list', '?block', '}' ]
    } ],
  },
  'export-method' => {
    'before' => [ 'method-alias', 'va-method-defn' ],
    'rules' => [ {
      'pattern'  => [ 'export', 'method', '?type', '?ident', '?list' ],
      'template' => [ 'extern',           '?type', '?ident', '?list' ]
    } ],
  },
  'method' => {
    'before' => [ 'export-method', 'method-alias', 'va-method-defn' ],
    'rules' => [ {
      'pattern'  => [ 'method', '?type', '?ident', '?list' ],
      'template' => [ 'static', '?type', '?ident', '?list' ]
    } ],
  },
  'super' => {
    'before' => [],
    'rules' => [ { # try to merge both super rules (make the va: optional)
      'pattern'  => [ 'dk', '?/(::?)/',             '?ident', '(', 'super',                                           '?list-member-term' ],
      'template' => [ 'dk', '?/(::?)/',             '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
    }, {   # for the very rare case that a user calls the dk:va: generic
      'pattern'  => [ 'dk', '?/(::?)/', 'va', '?/(::?)/', '?ident', '(', 'super',                                           '?list-member-term' ],
      'template' => [ 'dk', '?/(::?)/', 'va', '?4',       '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
    } ],
  },
  'slot-access' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [               'self',      '.',  '?ident' ],
      'template' => [ 'unbox', '(', 'self', ')', '->', '?ident' ]
    } ],
  },
  'explicit-box-literal' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ '?ident', '?/(::?)/', 'box', '(',                 '{', '?block-in', '}',      ')'  ],
      'template' => [ '?ident', '?/(::?)/', 'box', '?4', '?ident', '(', '{', '?block-in', '}', ')', '?8' ]
    } ],
  },
  'construct-klass-slots-literal' => {
    'before' => [ 'super', 'explicit-box-literal' ],
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
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'throw',                                       '?/(make|box)/', '(',  '?list-in', ')'       ],
      'template' => [ 'throw', 'dkt-capture-current-exception', '(', '?/(make|box)/', '?3', '?list-in', '?5', ')' ]
    } ],
  },
  'throw-make-or-box-parens' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'throw', '(',                                        '?/(make|box)/', '(',  '?list-in', ')',  ')'       ],
      'template' => [ 'throw', '?2', 'dkt-capture-current-exception', '(', '?/(make|box)/', '?4', '?list-in', '?6', '?7', ')' ]
    } ],
  },
  'make' => {
    'before' => [ 'throw-make-or-box', 'throw-make-or-box-parens' ],
    'rules' => [ {
      'pattern'  => [ 'make',                                       '(',  '?list-member'      ],
      'template' => [ 'dk', '::', 'init', '(', 'dk', '::', 'alloc', '?2', '?list-member', ')' ]
    } ],
  },
  'export-enum' => {
    'before' => [],
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
  'if-or-while-in-keys-or-elements-iterable' => { # optional 'not' and optional 'keys|elements'
    'before' => [],
    'rules' => [ {
      'pattern'  => [ '?/(if|while)/', '(',  '?ident', 'in',             '?/(keys|elements)/',      '?list-member',      ')'  ],
      'template' => [ '?/(if|while)/', '?2', '?ident', 'in', 'dk', '::', '?/(keys|elements)/', '(', '?list-member', ')', '?7' ]
    } ],
  },
  'if-or-while' => { # this could just have patterns (a missing template implies echoing the pattern match)
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'if' ],
      'template' => [ 'if' ],
    }, {
      'pattern'  => [ 'while' ],
      'template' => [ 'while' ],
    } ],
  },
  # if|while (e [not] in tbl)
  'if-or-while-in-iterable' => { # optional 'not'
    'before' => [ 'if-or-while-in-keys-or-elements-iterable' ],
    'aux-rules' => { # this could just have patterns (a missing template implies echoing the pattern match)
      '?cond-open' =>  [ { 'pattern' => [ '(' ], 'template' => [ '(' ] } ],
      '?cond-close' => [ { 'pattern' => [ ')' ], 'template' => [ ')' ] } ],
    },
    'rules' => [ {
      'pattern'  => [ '?/(if|while)/', '(',  '?ident',             'in',      '?list-member',                     ')'  ],
      'template' => [ '?/(if|while)/', '?2',           'dk', '::', 'in', '(', '?list-member', ',', '?ident', ')', '?6' ]
    } ],
  },
  # for (object-t e [not] in [keys|elements] tbl)
  'for-in-iterable-with-keys-or-elements' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'for', '(',  'object-t', '?ident', 'in',             '?/(keys|elements)/',      '?list-member',      ')'  ],
      'template' => [ 'for', '?2', 'object-t', '?ident', 'in', 'dk', '::', '?/(keys|elements)/', '(', '?list-member', ')', '?8' ]
    } ],
  },
  # for (object-t e [not] in seq)
  'for-in-iterable' => {
    'before' => [ 'for-in-iterable-with-keys-or-elements' ],
    'rules' => [ {
      'pattern'  => [ 'for', '(', 'object-t', '?ident', 'in', '?list-member', ')' ],
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

  # $()   tuple
  # $[]   vector
  # ${}   set
  # ${=>} table

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
