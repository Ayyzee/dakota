# default values
# optional sequence of tokens (more than one)
# resolve concatenation and stringification

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
    #
    # klass     ?ident {
    # =>
    # namespace ?ident {
    'klass-trait-decl-defn' => {
        'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/klass|trait/', '?ident', ';'      ],
		'template' => [ 'namespace',      '?ident', '{', '}' ]
	    },
	    {
		'pattern'  => [ '?/klass|trait/', '?ident', '{' ],
		'template' => [ 'namespace',      '?ident', '{' ]
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
    #
    #       ?ident => ?list-member
    # =>
    #  $ ## ?ident ,  ?list-member
    'keyword-args-defn' => {
	'dependencies' => [],
	'rules' => [
	    {
		'pattern'  => [ '?type',   '?ident', '=>', '?list-member', ],
		'template' => [ '?type',   '?ident',                       ]
	    },
	    {
		'pattern'  => [            '?ident', '=>',  ],
		'template' => [ '$', '##', '?ident', ',',   ]
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
    #
    # dk:va:?ident(super ,|)
    # =>
    # dk:va:?ident(super:construct(self,klass) ,|)
    'super' => {
	'dependencies' => [],
	'rules' => [ # the last term is there to prevent infinite recursion
	    {
		'pattern'  => [ 'dk', ':',            '?ident', '(', 'super',                                                   '?list-member-term' ],
		'template' => [ 'dk', ':',            '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', '?list-member-term' ]
	    },
	    {   # for the very rare case that a user calls the dk:va: generic
		'pattern'  => [ 'dk', ':', 'va', ':', '?ident', '(', 'super',                                                   '?list-member-term' ],
		'template' => [ 'dk', ':', 'va', ':', '?ident', '(', 'super', ':', 'construct', '(', 'self', ',', 'klass', ')', '?list-member-term' ]
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
		'pattern'  => [ '?ident', ':', 'box', '(',                              '{', '?block-in', '}', ')' ],
		'template' => [ '?ident', ':', 'box', '?4', '?ident', ':', 'construct', '(', '?block-in', ')', '?8' ]
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
		'pattern'  => [ 'throw',                              'make', '(', ],
		'template' => [ 'throw', 'dk-current-exception', '=', 'make', '(', ]
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
		'pattern'  => [ 'make',                                     '(',  '?list-member'      ],
		'template' => [ 'dk', ':', 'init', '(', 'dk', ':', 'alloc', '?2', '?list-member', ')' ]
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
		'pattern'  => [ '?/if|while/', '(',  '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')'  ],
		'template' => [ '?/if|while/', '?2', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', '?7' ]
	    },
	    {
		'pattern'  => [ 'for', '(',  'object-t', '?ident', 'in',            '?/keys|elements/',      '?list-member',      ')'  ],
		'template' => [ 'for', '?2', 'object-t', '?ident', 'in', 'dk', ':', '?/keys|elements/', '(', '?list-member', ')', '?8' ]
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
		'pattern'  => [ '?/if|while/', '(',                        '?ident', 'in', '?list-member',      ')' ],
		'template' => [ '?/if|while/', '?2', 'dk', ':', 'in', '(', '?ident', ',',  '?list-member', ')', '?6' ]
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
		'template' => [ 'for', '?2', 'object-t', '_iterator_', '=', 'dk', ':', 'forward-iterator', '(', '?list-member', ')', ';',
			   'object-t', '?ident', '=', 'dk', ':', 'next', '(', '_iterator_', ')', ';', '?7' ]
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
