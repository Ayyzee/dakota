{
    'throw-capture-exception' => {
        'dependencies' => [],

        'rules' => [ {
            'pattern' =>  [ 'throw',                              'make' ],
            'template' => [ 'throw', 'dk-current-exception', '=', 'make' ],
                     }
            ],

        #'lhs' => [ 'throw',                              'make', '?list' ],
        #'rhs' => [ 'throw', 'dk-current-exception', '=', 'make', '?list' ],
    }
}
