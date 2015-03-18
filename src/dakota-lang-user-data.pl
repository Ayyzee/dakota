{
    'kw-args-ident' => { # variable per project (lib or exe)
	'init'   => 1, # rhs = num-fixed args
	'append' => 2  # rhs = num-fixed args
    },
    'visibility' => { # constant for a language
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
}
