#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use Test::More;
use PerlX::Range;

my $r = 1..10;
is($r->items, 10);

done_testing;
