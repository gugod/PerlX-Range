#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use PerlX::Range;
use Test::More;

my $a = 1..10:by(2);

is_deeply(\@$a, [1,3,5,7,9]);

done_testing;
