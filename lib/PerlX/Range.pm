package PerlX::Range;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.04';

use PPI;
use PPI::Document;
use Devel::Declare ();
use B::OPCheck ();

sub __const_check {
    my $op = shift;
    my $offset = Devel::Declare::get_linestr_offset;
    $offset += Devel::Declare::toke_skipspace($offset);
    my $linestr = Devel::Declare::get_linestr;
    my $code = substr($linestr, $offset);

    my $doc = PPI::Document->new(\$code);
    $doc->index_locations;
    my $found = $doc->find(
        sub {
            my $node = $_[1];
            $node->content eq '..' && $node->class eq 'PPI::Token::Operator';
        }
    );
    return unless $found;

    my $obj_arguments = {};
    my $original_code = $code;
    $code = "";
    for my $op_range (@$found) {
        my $start = $op_range->sprevious_sibling;
        my $end = $op_range->snext_sibling;

        my $pnode = $op_range->sprevious_sibling;
        while($pnode) {
            my $prev_node = $pnode;
            while ($prev_node = $prev_node->previous_sibling) {
                $code = $prev_node->content . $code;
            }
            $pnode = $pnode->parent;
        }

        my $end_content = $end->content;

        if ($end_content eq '*') {
            $end_content = '"*"';
        }
        elsif ($end_content eq '*:') {
            my $selector = $end->snext_sibling;
            if ($selector->content eq 'by') {
                my $selector_arg = $selector->snext_sibling;
                if ($selector_arg && "$selector_arg" =~ /\((\d+)\)/) {
                    $obj_arguments->{by} = $1;
                }
            }
            else {
                die("Unknown Range syntax: $selector");
            }
            $end_content = '"*"';
        }
        else {
            my $colon = $end->snext_sibling;
            if ($colon->content eq ':') {
                my $selector = $colon->snext_sibling;
                if ($selector && $selector->content eq 'by') {
                    my $selector_arg = $selector->snext_sibling;
                    if ($selector_arg && "$selector_arg" =~ /\((\d+)\)/) {
                        $obj_arguments->{by} = $1;
                    }
                }
                else {
                    die("Unknown Range syntax: $selector");
                }
            }
        }

        $obj_arguments->{last} = $end_content;

        my $argument_string = "";
        for (keys %$obj_arguments) {
            $argument_string .= "$_ => " . $obj_arguments->{$_} . ", ";
        }
        $code .= ($start ? $start->content : "") . "+" . "PerlX::Range->new($argument_string)";
    }

    substr($linestr, $offset, length($original_code) - 2 ) = $code;
    Devel::Declare::set_linestr($linestr);
};

sub import {
    my $offset  = Devel::Declare::get_linestr_offset();
    my $linestr = Devel::Declare::get_linestr();

    substr($linestr, $offset, 0) = q[BEGIN { B::OPCheck->import($_ => check => \&PerlX::Range::__const_check) for qw(const); }];
    Devel::Declare::set_linestr($linestr);
}

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
    return bless {%args}, $class;
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
