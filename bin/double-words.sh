#!/bin/sh

perl -ne 'print "$ARGV:$.:$_" if m{\b(\w{2,})\1\b}' $@

