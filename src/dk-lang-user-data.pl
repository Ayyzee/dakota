{
    'ka-generics' => {
	'init' => 1,
    },
    'visibilities' => {
	'export'   => 1,
	'import'   => 1,
	'noexport' => 1
    },
    'list' => { 'open'  => '(',
		'sep'   => ',',
		'close' => ')',
		'member' => { 'term' => { ',' => 1,
					  ')' => 1 }}},
}
