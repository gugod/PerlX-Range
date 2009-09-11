#!/usr/bin/env perl -w
use strict;
use warnings;
use 5.010;
use Test::More;
use PerlX::Range;
use PerlX::MethodCallWithBlock;

my $a = 1..10;

my $b = 1;
$a->each {
    my ($self, $x) = @_;
    is($self, $a);
    is($_, $b);
    is($_, $x);
    $b++;
};

done_testing;
