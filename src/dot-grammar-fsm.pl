# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{ 'graph' => { 'center' => 'true',
               'fontcolor' => 'red',
               'fontsize' => '16',
               'label' => '\G',
               'rankdir' => 'LR'
             },
  'edge'  => { 'fontname' => 'Courier',
               'fontsize' => '16'
             },
  'node'  => { 'fontsize' => '16',
               'shape' => 'circle',
               'width' => '0.6'
             },
  '-stmts' => [ [ [ '00' ], { 'label' => '', 'style' => 'invis' } ],
                [ [ '00', '01' ], { } ],
                [ [ '01', '02' ], { 'label' => 'digraph|graph' } ],
                [ [ '01', '03' ], { 'label' => 'digraph|graph' } ],
                [ [ '02', '03' ], { 'label' => '"name"' } ],
                [ [ '03', '04' ], { 'label' => '{' } ],
                [ [ '04' ], { 'shape' => 'doublecircle' } ],
                [ [ '04', '02' ], { 'label' => 'subgraph' } ],
                [ [ '04', '03' ], { 'label' => 'subgraph', 'style' => 'dashed' } ],
                [ [ '04', '04' ], { 'label' => '}' } ],
                [ [ '04', '05' ], { 'label' => '"node"' } ],
                [ [ '04', '06' ], { 'label' => 'graph|edge|node' } ],
                [ [ '05', '04' ], { 'label' => ';', 'style' => 'dashed' } ],
                [ [ '05', '05' ], { 'label' => '->|-- "node"' } ],
                [ [ '05', '07' ], { 'label' => '[' } ],
                [ [ '06', '07' ], { 'label' => '[' } ],
                [ [ '07', '08' ], { 'label' => '<attr> = "value"' } ],
                [ [ '07', '09' ], { 'label' => ']' } ],
                [ [ '08', '07' ], { 'label' => ',', 'style' => 'dashed' } ],
                [ [ '08', '09' ], { 'label' => ']' } ],
                [ [ '09', '04' ], { 'label' => ';', 'style' => 'dashed' } ],
      ]
}
