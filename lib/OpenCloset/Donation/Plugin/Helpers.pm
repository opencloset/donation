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

=head2 status2label

    %= status2label($form->status);
    # <span class="label label-default status-accept">승인</span>

=cut

sub status2label {
    my ( $self, $status ) = @_;

    my ( $class, $str );

    if ($status) {
        if ( $status eq 'accept' ) {
            $class = ' status-accept';
            $str   = '확인';
        }
        elsif ( $status eq 'sent' ) {
            $class = ' status-sent';
            $str   = '배송중';
        }
        elsif ( $status eq 'return' ) {
            $class = ' status-return';
            $str   = '반송중';
        }
        elsif ( $status eq 'done' ) {
            $class = ' status-done';
            $str   = '완료';
        }
        elsif ( $status eq 'cancel' ) {
            $class = ' status-cancel';
            $str   = '취소';
        }
    }
    else {
        $class = '';
        $str   = '없음';
    }

    my $html = Mojo::DOM::HTML->new;
    $html->parse(qq{<span class="label label-default$class">$str</span>});
    my $tree = $html->tree;

    return Mojo::ByteStream->new( Mojo::DOM::HTML::_render($tree) );
}

1;

__END__

=head1 COPYRIGHT

The MIT License (MIT)

Copyright (c) 2016 열린옷장

=cut
