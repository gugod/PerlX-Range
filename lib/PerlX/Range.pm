package PerlX::Range;

use strict;
use warnings;
use 5.010;
use B::Hooks::OP::Check;
use B::Hooks::EndOfScope;

our $VERSION = '0.04';

use overload
    '@{}' => sub {
        my $self = shift;
        my @a = $self->to_a;
        return \@a;
    },
    '+' => sub {
        my $self = shift;
        $self->{first} = $_[0];
        return $self;
    },
    '""' => sub {
        my $self = shift;
        return $self->{first} . ".." . $self->{last};
    };

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    $self->{current} = $self->min;
    $self->{by} = 1;
    return $self;
}

sub xrange {
    my ($first, $last) = @_;
    return __PACKAGE__->new(first => $first, last => $last);
}

sub items {
    $_[0]->{last} - $_[0]->{first} + 1
}

sub first {
    $_[0]->{first}
}

sub last {
    $_[0]->{last}
}

*min = *from = \&first;
*max = *to   = \&last;

sub to_a {
    my $self = shift;
    my @r = ();
    $self->each(sub { push @r, $_ });
    return @r;
}

sub by {
    my ($self, $n) = @_;
    $self->{by} = $n if $n;
    return $self;
}

sub each {
    my $cb = pop;
    my $self = shift;

    my $current = $self->min;
    while('*' eq $self->max || $current <= $self->max) {
        local $_ = $current;
        my $ret = $cb->($self, $_);
        last if (defined($ret) && !$ret);
        $current += $self->{by} ? $self->{by} : 1;
    }
}

sub next {
    my $self = shift;

    if ($self->{current} > $self->max) {
        $self->{current} = $self->min;
        return;
    }
    $self->{current} += 1;
    return $self->{current}-1;
}

require XSLoader;
XSLoader::load('PerlX::Range', $VERSION);

sub import {
    return if $^H{PerlXRange};

    feature->import(':5.10');
    $^H &= 0x00020000;
    $^H{PerlXRange} = 1;

    add_flop_hook();
    on_scope_end {
        remove_flop_hook();
    };
}

sub unimport {
    remove_flop_hook();
    $^H &= ~0x00020000;
    delete $^H{PerlXRange};
}


1;
__END__

=head1 NAME

PerlX::Range - Lazy Range object in Perl 5

=head1 SYNOPSIS

  use PerlX::MethodCallWithBlock;
  use PerlX::Range;

  my $a = 1..5000;

  $a->each {
      # $_ is the current value

      return 0 if should_break($_);
  };

=head1 DESCRIPTION

PerlX::Range is an attemp to implement make range operator lazy. When you say:

    my $a = 1..10;

This `$a` variable is then now a C<PerlX::Range> object.

At this point the begin of range can only be a constant, and better
only be a number literal.

The end of the range can be a number, or a asterisk C<*>, which means
"whatever", or Inf. This syntax is stolen from Perl6.

After the end of range, it optionally take a C<:by(N)> modifier, where
N can be a number literal. This syntax is also stolen from Perl6.

Therefore, this is how you represent all odd numbers:

    my $odd = 1..*:by(2);


=head1 METHODS

=over 4

=item min, from, first

Retrieve the minimum value of the range.

=item max, to, last

Retrieve the maximum value of the range.

=item each($cb)

Iterate over the range one by one, the C<$cb> should be a code
ref. Inside the body of that, C<$_> refers to the current value.

If you want to stop before it reach the end of the range, or you have
to because the range is infinite, you need to say C<return 0>. A
defined false value from C<$cb> will make the iteration stop.

=back

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
