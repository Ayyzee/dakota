{
    # include  ?dquote-str ;
    # =>
    # #include ?dquote-str
    'include-stmt' => {
        'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [      'include', '?dquote-str', ';' ],
		'template' => [ '#', 'include', '?dquote-str'      ]
	    }
	],
    },

    # how about include <...> ;

    # klass     ?ident ;
    # =>
    # namespace ?ident {}
    'klass-decl' => {
        'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'klass',     '?ident', ';'      ],
		'template' => [ 'namespace', '?ident', '{', '}' ]
	    }
	],
    },

    # klass     ?ident {
    # =>
    # namespace ?ident {
    'klass-defn' => {
        'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'klass',     '?ident', '{' ],
		'template' => [ 'namespace', '?ident', '{' ]
	    }
	],
    },

    # superklass ?ident ;
    # =>
    # 
    'superklass-decl' => {
        'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'superklass', '?ident', ';' ],
		'template' => []
	    },
	],
    },

    # how about klass ?ident ;
    # how about trait ?list-in ;

    # slots          { ... }
    # =>
    # struct slots-t { ... } ;
    'slots-defn' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'slots',             '?block',     ],
		'template' => [ 'struct', 'slots-t', '?block', ';' ]
	    }
	],
    },

    # ?type => ?list-member ,|)
    # =>
    # ?type                 ,|)
    'keyword-args-defn' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ '?type', '?ident', '=>', '?list-member', '?list-member-term' ], # we can drop the last one
		'template' => [ '?type', '?ident',                       '?list-member-term' ]  # we can drop the last one
	    }
	],
    },

    # dk:     ?ka-ident ( ?list-in       )
    # =>
    # dk: va: ?ka-ident ( ?list-in, NULL )
    'keyword-args-wrap' => {
	'dependencies' => [ 'keyword-args-defn', 'super' ],
	'rules' => [
	    {
		'pattern'  => [ 'dk', ':',            '?ka-ident', '(', '?list-in',              ')' ],
		'template' => [ 'dk', ':', 'va', ':', '?ka-ident', '(', '?list-in', ',', 'NULL', ')' ]
	    }
	],
    },

    #       ?ident => ?list-member
    # =>
    #  $ ## ?ident ,  ?list-member
    'keyword-args-use' => {
	'dependencies' => [ 'keyword-args-defn' ],
	'rules' => [
	    {
		'pattern'  => [            '?ident', '=>', '?list-member' ], # we can drop the last one
		'template' => [ '$', '##', '?ident', ',',  '?list-member' ]  # we can drop the last one
	    }
	],
    },

    # method alias (...)
    # =>
    # method
    'method-alias' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'method', 'alias', '?list' ],
		'template' => [ 'method'                   ]
	    }
	],
    },

    #                ?visibility method ?type va : ?ident(...) { ... }
    # =>
    # namespace va { ?visibility method ?type      ?ident(...) { ... } }
    'va-method' => {
	'dependencies' => [ 'method-alias' ],
	'rules' => [
	    {
		'pattern'  => [                         '?visibility', 'method', '?type', 'va', ':', '?ident', '?list', '?block'      ],
		'template' => [ 'namespace', 'va', '{', '?visibility', 'method', '?type',            '?ident', '?list', '?block', '}' ]
	    }
	],
    },

    # export method ?type ?ident(...)
    # =>
    # extern        ?type ?ident(...)
    'export-method' => {
	'dependencies' => [ 'method-alias', 'va-method' ],
	'rules' => [
	    {
		'pattern'  => [ 'export', 'method', '?type', '?ident', '?list' ],
		'template' => [ 'extern',           '?type', '?ident', '?list' ]
	    }
	],
    },

    # method ?type ?ident(...)
    # =>
    # static ?type ?ident(...)
    'method' => {
	'dependencies' => [ 'export-method', 'method-alias', 'va-method' ],
	'rules' => [
	    {
		'pattern'  => [ 'method', '?type', '?ident', '?list' ],
		'template' => [ 'static', '?type', '?ident', '?list' ]
	    }
	],
    },

    # try to merge super and va-super (make the va: optional)

    # dk:?ident(super ,|)
    # =>
    # dk:?ident(super:construct(self,klass) ,|)
    'super' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'dk', ':', '?ident', '(', 'super',                                                   '?list-member-term' ], # we can drop the last one
		'template' => [ 'dk', ':', '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', '?list-member-term' ]  # we can drop the last one
	    }
	],
    },

    # for the very rare case that a user calls the dk:va: generic
    # dk:va:?ident(super ,|)
    # =>
    # dk:va:?ident(super:construct(self,klass) ,|)
    'va-super' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'dk', ':', 'va', ':', '?ident', '(', 'super',                                                   '?list-member-term' ], # we can drop the last one
		'template' => [ 'dk', ':', 'va', ':', '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', '?list-member-term' ]  # we can drop the last one
	    }
	],
    },

    # self.?ident
    # =>
    # unbox(self)->?ident
    'slot-access' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [               'self',      '.',  '?ident' ],
		'template' => [ 'unbox', '(', 'self', ')', '->', '?ident' ]
	    }
	],
    },

    # ?ident:box({ ... })
    # =>
    # ?ident:box(?ident:construct(...))
    'box-arg-compound-literal' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ '?ident', ':', 'box', '(',                             '{', '?block-in', '}', ')' ],
		'template' => [ '?ident', ':', 'box', '(', '?ident', ':', 'construct', '(', '?block-in', ')', ')' ]
	    }
	],
    },

    # throw                        make (
    # =>
    # throw dk-current-exception = make (
    'throw-capture-exception' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'throw',                              'make', '(', '?list-in', ')' ], # we can drop the last two
		'template' => [ 'throw', 'dk-current-exception', '=', 'make', '(', '?list-in', ')' ], # we can drop the last two
	    }
	],
    },

    # make    (            ?ident   ,|)
    # =>
    # dk:init ( dk:alloc ( ?ident ) ,|)
    'make' => {
	'dependencies' => [ 'throw-capture-exception' ],
	'rules' => [
	    {
		'pattern'  => [ 'make',                                     '(', '?list-member',      '?list-member-term' ], # we can drop the last one
		'template' => [ 'dk', ':', 'init', '(', 'dk', ':', 'alloc', '(', '?list-member', ')', '?list-member-term' ]  # we can drop the last one
	    }
	],
    },

    # export enum ?type-ident { ... }
    # =>
    # 
    'export-enum' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ 'export', 'enum', '?type-ident', '?block' ],
		'template' => []
	    }
	],
    },

    # ?ident in      keys|elements   ?expr   )
    # =>
    # ?ident in dk : keys|elements ( ?expr ) )
    'in-keys-or-elements-testing' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/if|while/', '(', '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')' ],
		'template' => [ '?/if|while/', '(', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', ')' ]
	    },
	    {
		'pattern'  => [ 'for', '(', 'object-t', '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')' ],
		'template' => [ 'for', '(', 'object-t', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', ')' ]
	    },
	],
    },

    # if (      ?ident in  keys ?list-member)
    # becomes
    # if (dk:in(?ident, dk:keys(?list-member)))
    #
    # if (?ident in         ?list-member)
    # becomes
    # if (    dk:in(?ident, ?list-member))
    'if-while-set-membership-testing' => {
	'dependencies' => [ 'in-keys-or-elements-testing' ],
	'rules' => [
	    {
		'pattern'  => [ '?/if|while/', '(',                       '?ident', 'in', '?list-member',      ')' ],
		'template' => [ '?/if|while/', '(', 'dk', ':', 'in', '(', '?ident', ',',  '?list-member', ')', ')' ]
	    }
	],
    },

    # for (object-t ?ident in                        ?list-member)
    # =>
    # for (object_t _iterator_ = dk:forward_iterator(?list-member); object_t ?ident = dk:next(_iterator_); )
    'for-forward-iterator' => {
	'dependencies' => [ 'in-keys-or-elements-testing' ],
	'rules' => [
	    {
		'pattern'  => [ 'for', '(', 'object-t', '?ident', 'in', '?list-member', ')' ],
		'template' => [ 'for', '(', 'object-t', '_iterator_', '=', 'dk', ':', 'forward-iterator', '(', '?list-member', ')', ';',
			   'object-t', '?ident', '=', 'dk', ':', 'next', '(', '_iterator_', ')', ';', ')' ]
	    },
	],
    },

    # $()   tuple
    # $[]   vector
    # ${}   set
    # ${=>} table

    # foo:slots-t* slt = unbox(bar)
    # becomes
    # foo:slots-t* slt = foo:unbox(bar)

    # foo:slots-t& slt = *unbox(bar)
    # becomes
    # foo:slots-t& slt = *foo:unbox(bar)

    # foo-t* slt = unbox(bar)
    # becomes
    # foo-t* slt = foo:unbox(bar)

    # foo-t& slt = *unbox(bar)
    # becomes
    # foo-t& slt = *foo:unbox(bar)
}
