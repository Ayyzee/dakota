{
    'ka-ident' => { # variable per project (lib or exe)
	'init'   => 1, # rhs = num-fixed args
	'append' => 2  # rhs = num-fixed args
    },
    'visibility' => { # constant for a language
	'export'   => 1,
	'import'   => 1,
	'noexport' => 1
    },
    'list' => { 'open'  => '(', # constant for a language
		'sep'   => ',',
		'close' => ')',
		'member' => { 'term' => { ',' => 1,
					  ')' => 1 }}},
}
