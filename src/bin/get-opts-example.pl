#!/usr/bin/perl -w -I ../bin -I /usr/local/dakota/bin

use strict;
use Dakota;

use Data::Dumper;
$Data::Dumper::Terse     = 1;
$Data::Dumper::Deepcopy  = 1;
$Data::Dumper::Purity    = 1;
$Data::Dumper::Quotekeys = 1;
$Data::Dumper::Indent    = 1; # default = 2

use Getopt::Long;
$Getopt::Long::ignorecase = 0;

my $opts = {};
my $opts_seqs = [ 'rep' ];
&Dakota::preprocess_opts($opts, $opts_seqs);
&GetOptions($opts,
            'bootstrap',
            'bootstrapclean',
            'clean',
            'precompile',
            'compile',
            'link-shared',
            'link-dynamic',
            'rep=s' => $$opts{'rep'},
            'directory=s', # assume never used
            'output=s',    # assume always used
            );
&Dakota::postprocess_opts($opts, $opts_seqs);

print Dumper $opts;
