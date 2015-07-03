# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{
  'box-symbol' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [ 'box', '(',                              '?/\#([a-zA-Z0-9-]+)/', ')' ],
      'template' => [ 'box', '(', '__symbol', '::', '_', '##', '?3',                   ')' ],
    } ],
  },
  'literal-pair' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [        '#(',                                                 '?symbol',      ':',                            '?list-member',      ')' ],
      'template' => [ 'make', '(', 'LITERAL-PAIR', ',', '#first', ':', 'box', '(', '?symbol', ')', ',',  '#last', ':', 'box', '(', '?list-member', ')', ')' ]
    } ],
  },
  'literal-table' => {
    'before' => [],
    'rules' => [ {
      'pattern'  => [        '#{',                                                                                                     '?block-in',      '}' ],
      'template' => [ 'make', '(', 'LITERAL-TABLE', ',', '#items', ':', 'cast', '(', 'object-t', '[', ']', ')', '{', 'NULL-PAIR', ',', '?block-in', '}', ')' ]
    } ],
  },
  'literal-table-pair' => {
    'before' => [ 'literal-table' ],
    'rules' => [ {
      'pattern'  => [ 'NULL-PAIR', ',',       '?symbol', ':', '?list-member'                        ],
      'template' => [                   '#(', '?symbol', ':', '?list-member', ')', ',', 'NULL-PAIR' ]
    }, {
      'pattern'  => [ 'NULL-PAIR',   '}' ],
      'template' => [ 'NULL-PAIR-X', '}' ],
    } ],
  },
  'make' => {
    'before' => [ 'literal-table-pair', 'literal-pair' ],
    'rules' => [ {
      'pattern'  => [ 'make',                                       '(',  '?list-member'      ],
      'template' => [ 'dk', '::', 'init', '(', 'dk', '::', 'alloc', '?2', '?list-member', ')' ]
    } ],
  },
  'keyword-args-use' => {
    'before' => [ 'make', 'literal-table-pair', 'literal-pair' ],
    'rules' => [ {
      'pattern'  => [ 'NULL-KEYWORD', ',',                               '?/\#([a-zA-Z0-9-]+)/', ':', '?list-member'                       ],
      'template' => [                      '__keyword', '::', '_', '##', '?3',                   ',', '?list-member', ',', 'NULL-KEYWORD'  ]
    }, {
      'pattern'  => [                                                    '?/\#([a-zA-Z0-9-]+)/', ':', '?list-member'                       ],
      'template' => [                      '__keyword', '::', '_', '##', '?1',                   ',', '?list-member', ',', 'NULL-KEYWORD'  ] 
    }, {
      'pattern'  => [ 'NULL-KEYWORD',   ')' ],
      'template' => [ 'NULL-KEYWORD-X', ')' ],
    } ],
  },
}
