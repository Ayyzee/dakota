# -*- mode: cperl -*-
# -*- cperl-close-paren-offset: -2 -*-
# -*- cperl-continued-statement-offset: 2 -*-
# -*- cperl-indent-level: 2 -*-
# -*- cperl-indent-parens-as-block: t -*-
# -*- cperl-tab-always-indent: t -*-

{
    'throw-make-or-box' => {
        'before' => [],
        'after' =>  [],

        'rules' => [ {
            'pattern' =>  [ 'throw',                               '?/make|box/' ],
            'template' => [ 'throw', 'dkt-current-exception', '=', '?/make|box/' ],
                     }
            ],
    }
}
