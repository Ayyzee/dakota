{
    'include-stmt' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [      'include', '?dquote-str', ';' ],
		'template' => [ '#', 'include', '?dquote-str'      ]
	    }
	],
    },
    'klass-or-trait-decl' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/klass|trait/', '?ident', ';' ],
		'template' => []
	    },
	],
    },
    'klass-or-trait-defn' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/klass|trait/', '?ident', '{' ],
		'template' => [ 'namespace',      '?ident', '{' ]
	    }
	],
    },
    'superklass-decl' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'superklass', '?ident', ';' ],
		'template' => []
	    },
	],
    },
    'slots-defn' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'slots',             '?block',     ],
		'template' => [ 'struct', 'slots-t', '?block', ';' ]
	    }
	],
    },
    'keyword-args-defn' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ '?type', '?ident', '=>', '?list-member', ],
		'template' => [ '?type', '?ident',                       ]
	    },
	],
    },
    'keyword-args-use' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'nullptr-KEYWORD', ',', '?ident', '=>', '?list-member'                       ],
		'template' => [           '$', '##', '?ident', ',',  '?list-member', ',', 'nullptr-KEYWORD'  ]
	    },
	    {
		'pattern'  => [                 ',', '?ident', '=>', '?list-member'                       ],
		'template' => [      ',', '$', '##', '?ident', ',',  '?list-member', ',', 'nullptr-KEYWORD'  ]
	    }
	],
    },
    'keyword-args-wrap' => {
	'before' => [ 'keyword-args-use', 'super' ],
	'rules' => [
	    {
		'pattern'  => [ 'dk', ':', '?ka-ident-1', '(', '?list-member',                      ')' ],
		'template' => [ 'dk', ':', '?ka-ident-1', '(', '?list-member', ',', 'nullptr-KEYWORD', ')' ]
	    },
	    {
		'pattern'  => [ 'dk', ':', '?ka-ident-2', '(', '?list-member', ',', '?list-member',                      ')' ],
		'template' => [ 'dk', ':', '?ka-ident-2', '(', '?list-member', ',', '?list-member', ',', 'nullptr-KEYWORD', ')' ]
	    }
	],
    },
    'method-alias' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'method', 'alias', '?list' ],
		'template' => [ 'method'                   ]
	    }
	],
    },
    'va-method-defn' => {
	'before' => [ 'method-alias' ],
	'rules' => [
	    {
		'pattern'  => [                         '?visibility', 'method', '?type', 'va', ':', '?ident', '?list', '?block'      ],
		'template' => [ 'namespace', 'va', '{', '?visibility', 'method', '?type',            '?ident', '?list', '?block', '}' ]
	    }
	],
    },
    'export-method' => {
	'before' => [ 'method-alias', 'va-method-defn' ],
	'rules' => [
	    {
		'pattern'  => [ 'export', 'method', '?type', '?ident', '?list' ],
		'template' => [ 'extern',           '?type', '?ident', '?list' ]
	    }
	],
    },
    'method' => {
	'before' => [ 'export-method', 'method-alias', 'va-method-defn' ],
	'rules' => [
	    {
		'pattern'  => [ 'method', '?type', '?ident', '?list' ],
		'template' => [ 'static', '?type', '?ident', '?list' ]
	    }
	],
    },
    'super' => {
	'before' => [],
	'after' => [ 'construct-klass-slots-literal' ],
	'rules' => [ # try to merge both super rules (make the va: optional)
	    {
		'pattern'  => [ 'dk', ':',            '?ident', '(', 'super',                                           '?list-member-term' ],
		'template' => [ 'dk', ':',            '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
	    },
	    {   # for the very rare case that a user calls the dk:va: generic
		'pattern'  => [ 'dk', ':', 'va', ':', '?ident', '(', 'super',                                           '?list-member-term' ],
		'template' => [ 'dk', ':', 'va', ':', '?ident', '(', 'super', '(', '{', 'self', ',', 'klass', '}', ')', '?list-member-term' ]
	    }
	],
    },
    'slot-access' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [               'self',      '.',  '?ident' ],
		'template' => [ 'unbox', '(', 'self', ')', '->', '?ident' ]
	    }
	],
    },
    'explicit-box-literal' => {
	'before' => [],
	'after' => [ 'construct-klass-slots-literal' ],
	'rules' => [
	    {
		'pattern'  => [ '?ident', ':', 'box', '(',                 '{', '?block-in', '}',      ')'  ],
		'template' => [ '?ident', ':', 'box', '?4', '?ident', '(', '{', '?block-in', '}', ')', '?8' ]
	    }
	],
    },
    'construct-klass-slots-literal' => {
	'before' => [],
	'rules' => [
	    {   # ?ident is a klass-name
		'pattern'  => [ '?ident',                       '(', '{', '?block-in', '}', ')' ],
		'template' => [ '?ident',     ':', 'construct', '(',      '?block-in',      ')' ]
	       #'template' => [ 'cast', '(', '?{ident}-t', ')',      '{', '?block-in', '}'      ]
	       #'template' => [ '?{ident}-t',                   '(',      '?block-in',      ')' ]
	    }
	],
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
	'rules' => [
	    {
		'pattern'  => [ 'throw',          '?/make|box/', '(',  '?list-in', ')'       ],
		'template' => [ 'dkt-throw', '(', '?/make|box/', '?3', '?list-in', '?5', ')' ]
	    }
	],
    },
    'throw-make-or-box-parens' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'throw',     '(',  '?/make|box/', '(',  '?list-in', ')',  ')'  ],
		'template' => [ 'dkt-throw', '?2', '?/make|box/', '?4', '?list-in', '?6', '?7' ]
	    }
	],
    },
    'make' => {
	'before' => [ 'throw-make-or-box', 'throw-make-or-box-parens' ],
	'rules' => [
	    {
		'pattern'  => [ 'make',                                     '(',  '?list-member'      ],
		'template' => [ 'dk', ':', 'init', '(', 'dk', ':', 'alloc', '?2', '?list-member', ')' ]
	    }
	],
    },
    'export-enum' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'export', 'enum', '?type-ident', '?block' ],
		'template' => []
	    }
	],
    },

    # ?(optional ?[ keys elements ] )
    # ?(optional not )
    # ?(optional va : )
    # ?(not ?look-ahead xx yy )
    # ?(not ?look-behind xx yy )

    # if|while (e [not] in [keys|elements] tbl)
    'if-or-while-in-keys-or-elements-iterable' => { # optional 'not' and optional 'keys|elements'
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/if/while/', '(',  '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')'  ],
		'template' => [ '?/if/while/', '?2', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', '?7' ]
	    },
	],
    },
    # if|while (e [not] in tbl)
    'if-or-while-in-iterable' => { # optional 'not'
	'before' => [ 'if-or-while-in-keys-or-elements-iterable' ],
	'rules' => [
	    {
		'pattern'  => [ '?/if/while/', '(',  '?ident',            'in',      '?list-member',                ')'  ],
		'template' => [ '?/if/while/', '?2',           'dk', ':', 'in', '(', '?list-member', '?ident', ')', '?6' ]
	    },
	],
    },
    # for (object-t e [not] in [keys|elements] tbl)
    'for-in-iterable-with-keys-or-elements' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [ 'for', '(',  'object-t', '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')'  ],
		'template' => [ 'for', '?2', 'object-t', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', '?8' ]
	    },
	],
    },
    # for (object-t e [not] in seq)
    'for-in-iterable' => {
	'before' => [ 'for-in-iterable-with-keys-or-elements' ],
	'rules' => [
	    {
		'pattern'  => [ 'for', '(', 'object-t', '?ident', 'in', '?list-member', ')' ],
		'template' => [ 'for', '?2', 'object-t', '_iterator_', '=', 'dk', ':', 'forward-iterator', '(', '?list-member', ')', ';',
				'object-t', '?ident', '=', 'dk', ':', 'next', '(', '_iterator_', ')', ';', '?7' ]
	    },
	],
    },

    # default values
    # optional sequence of tokens (more than one)
    # resolve concatenation and stringification
    # comments
    # how about include <...> ;
    # how about trait ?list-in ;

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
