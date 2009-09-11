package PerlX::Range;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';

use PPI;
use PPI::Document;
use Devel::Declare ();
use B::OPCheck ();

sub __const_check {
    my $op = shift;
    my $offset = Devel::Declare::get_linestr_offset;
    # $offset += Devel::Declare::toke_skipspace($offset);
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

        $code .= $start->content . "+" . "PerlX::Range->new(end => @{[ $end->content ]})";
    }

    # say $linestr;
    substr($linestr, $offset, length($original_code) - 2 ) = $code;
    # say $linestr;
    Devel::Declare::set_linestr($linestr);
};

sub import {
    my $offset  = Devel::Declare::get_linestr_offset();
    my $linestr = Devel::Declare::get_linestr();

    substr($linestr, $offset, 0) = q[BEGIN { B::OPCheck->import($_ => check => \&PerlX::Range::__const_check) for qw(const); }];
    Devel::Declare::set_linestr($linestr);
}

use overload
    '+' => sub {
        my $self = shift;
        $self->{start} = $_[0];
        return $self;
    },
    '""' => sub {
        my $self = shift;
        return $self->{start} . ".." . $self->{end};
    };

sub new {
    my ($class, %args) = @_;
    return bless {%args}, $class;
}

sub each {
    my $cb = pop;
    my $self = shift;

    my $current = $self->{current} ||= $self->{start};
    if ($current > $self->{end}) {
        delete $self->{current};
        return;
    }
    while($current <= $self->{end}) {
        local $_ = $current;
        my $ret = $cb->($self, $_);
        last if (defined($ret) && !$ret);
        $current++;
    }
}


1;
__END__

=head1 NAME

PerlX::Range -

=head1 SYNOPSIS

  use PerlX::Range;

=head1 DESCRIPTION

PerlX::Range is

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
