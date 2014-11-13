# default values
# optional sequence of tokens (more than one)
# resolve concatenation and stringification
# comments

{
    # include  ?dquote-str ;
    # =>
    # #include ?dquote-str
    'include-stmt' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [      'include', '?dquote-str', ';' ],
		'template' => [ '#', 'include', '?dquote-str'      ]
	    }
	],
    },

    # how about include <...> ;

    # klass|trait ?ident ;
    # =>
    #
    #
    # klass|trait ?ident {
    # =>
    # namespace   ?ident {
    'klass-trait-decl+defn' => {
        'before' => [],
	'rules' => [
	    {
		'pattern'  => [ '?/klass|trait/', '?ident', ';' ],
		'template' => []
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
        'before' => [],
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
	'before' => [],
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
    'keyword-args-defn+use' => {
	'before' => [],
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
	'before' => [ 'keyword-args-defn+use', 'super' ],
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
	'before' => [],
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
    'va-method-defn' => {
	'before' => [ 'method-alias' ],
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
	'before' => [ 'method-alias', 'va-method-defn' ],
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
	'before' => [ 'export-method', 'method-alias', 'va-method-defn' ],
	'rules' => [
	    {
		'pattern'  => [ 'method', '?type', '?ident', '?list' ],
		'template' => [ 'static', '?type', '?ident', '?list' ]
	    }
	],
    },

    # try to merge both super rules (make the va: optional)

    # dk:?ident(super ,|)
    # =>
    # dk:?ident(super-t(self,klass) ,|)
    #
    # dk:va:?ident(super ,|)
    # =>
    # dk:va:?ident(super-t(self,klass) ,|)
    'super' => {
	'before' => [],
	'after' => [ 'construct-klass-slots-literal' ],
	'rules' => [
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

    # self.?ident
    # =>
    # unbox(self)->?ident
    'slot-access' => {
	'before' => [],
	'rules' => [
	    {
		'pattern'  => [               'self',      '.',  '?ident' ],
		'template' => [ 'unbox', '(', 'self', ')', '->', '?ident' ]
	    }
	],
    },

    # ?{ident}-t ?ident = box({ ... })
    # =>
    # ?{ident}-t ?ident = ?{ident}:box({ ... })
    # or
    # ?type ?ident = box({ ... })
    # =>
    # ?type ?ident = box(cast(?type){ ... })

    # ?ident:box({ ... })
    # =>
    # ?ident:box(?ident({ ... }))
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

    # ?ident({ ... })
    # =>
    # ?ident:construct(...)
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

    # throw                        make (
    # =>
    # throw dk-current-exception = make (
    'throw-capture-exception' => {
	'before' => [],
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
	'before' => [ 'throw-capture-exception' ],
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
	'before' => [],
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
	'before' => [],
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
    # =>
    # if (dk:in(?ident, dk:keys(?list-member)))
    #
    # if (?ident in         ?list-member)
    # =>
    # if (    dk:in(?ident, ?list-member))
    'if-while-set-membership-testing' => {
	'before' => [ 'in-keys-or-elements-testing' ],
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
	'before' => [ 'in-keys-or-elements-testing' ],
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
