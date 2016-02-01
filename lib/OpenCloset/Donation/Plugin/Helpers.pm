package OpenCloset::Donation::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::DOM::HTML;

=encoding utf8

=head1 NAME

OpenCloset::Donation::Plugin::Helpers - opencloset donation mojo helper

=head1 SYNOPSIS

    # Mojolicious::Lite
    plugin 'OpenCloset::Donation::Plugin::Helpers';

    # Mojolicious
    $self->plugin('OpenCloset::Donation::Plugin::Helpers');

=cut

sub register {
    my ( $self, $app, $conf ) = @_;

    $app->helper( status2label => \&status2label );
}

=head1 HELPERS

=head2 status2label($status, $active)

    %= status2label($form->status);
    # <span class="label label-default status-accept">승인</span>
    # <span class="label label-default status-accept active"><i class="fa fa-archive"></i>$str</span>    # $active is true

=cut

sub status2label {
    my ( $self, $status, $active ) = @_;

    my ( $class, $str ) = ( '', '' );

    if ($status) {
        if ( $status eq 'accepted' ) {
            $class = " status-$status";
            $str   = '확인';
        }
        elsif ( $status eq 'waiting' ) {
            $class = " status-$status";
            $str   = '발송대기';
        }
        elsif ( $status eq 'delivering' ) {
            $class = " status-$status";
            $str   = '배송중';
        }
        elsif ( $status eq 'delivered' ) {
            $class = " status-$status";
            $str   = '발송완료';
        }
        elsif ( $status eq 'returning' ) {
            $class = " status-$status";
            $str   = '반송신청';
        }
        elsif ( $status eq 'returned' ) {
            $class = " status-$status";
            $str   = '반송완료';
        }
        elsif ( $status eq 'cancel' ) {
            $class = " status-$status";
            $str   = '취소';
        }
    }
    else {
        $status = '';
        $str    = '없음';
    }

    my $html = Mojo::DOM::HTML->new;

    if ($active) {
        $html->parse(
            qq{<span class="label label-default active $class" data-status="$status"><i class="fa fa-archive"></i>$str</span>}
        );
    }
    else {
        $html->parse(qq{<span class="label label-default$class" data-status="$status">$str</span>});
    }

    my $tree = $html->tree;
    return Mojo::ByteStream->new( Mojo::DOM::HTML::_render($tree) );
}

1;

__END__

=head1 COPYRIGHT

The MIT License (MIT)

Copyright (c) 2016 열린옷장

=cut
