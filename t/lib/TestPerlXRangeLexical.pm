package TestPerlXRangeLexical;
use strict;
use warnings;

sub test_range_ref {
    my @a = (1..10);
    return (ref($a[0]) eq '') && (scalar(@a) == 10);
}

1;
