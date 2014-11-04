{
    'throw-capture-exception' => {
        'dependencies' => [],

        'lhs' => [ 'throw',                              'make' ],
        'rhs' => [ 'throw', 'dk-current-exception', '=', 'make' ],

        #'lhs' => [ 'throw',                              'make', '?list' ],
        #'rhs' => [ 'throw', 'dk-current-exception', '=', 'make', '?list' ],
    }
}
