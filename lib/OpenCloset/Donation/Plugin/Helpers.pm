package OpenCloset::Donation::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::DOM::HTML;

use OpenCloset::Donation::Status;

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

    $app->helper( status2label  => \&status2label );
    $app->helper( update_status => \&update_status );
}

=head1 HELPERS

=head2 status2label($status, $active)

    %= status2label($form->status);
    # <span class="label label-default status-accept">승인</span>
    # <span class="label label-default status-accept active"><i class="fa fa-archive"></i>$str</span>    # $active is true

=cut

sub status2label {
    my ( $self, $status, $active ) = @_;
    $status ||= '';

    my ( $class, $str ) = ( '', '' );
    if ( my $label = $OpenCloset::Donation::Status::LABEL_MAP{$status} ) {
        $class = " status-$status" if $status;
        $str = $label;
    }

    my $html = Mojo::DOM::HTML->new;

    if ($active) {
        $html->parse(
            qq{<span class="label label-default active status$class" title="$status" data-status="$status"><i class="fa fa-archive"></i>$str</span>}
        );
    }
    else {
        $html->parse(
            qq{<span class="label label-default status$class" title="$status" data-status="$status">$str</span>});
    }

    my $tree = $html->tree;
    return Mojo::ByteStream->new( Mojo::DOM::HTML::_render($tree) );
}

=head2 update_status

    $self->update_status($form, $to);

=over

=item $form

L<OpenCloset::Schema::Result::DonationForm>

=item $to

string of status

=over

=item undef

C<undef>

=item waiting

=item delivering

=item delivered

=item returned

=item cancel

=item do-not-return

=item registered

=back

=cut

sub update_status {
    my ( $self, $form, $to ) = @_;
    return unless $form;

    $to ||= '';
    my $from = $form->status || '';
    return unless $to || $from;
    return if $from eq $to;

    $form->update( { status => $to || undef } );

    if ( $from eq $OpenCloset::Donation::Status::NULL && $to eq $OpenCloset::Donation::Status::DELIVERING ) {
        my $msg = $self->render_to_string( 'sms/null2delivering', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**0 } );
    }

    if ( $from eq $OpenCloset::Donation::Status::WAITING && $to eq $OpenCloset::Donation::Status::DELIVERING ) {
        my $msg = $self->render_to_string( 'sms/waiting2delivering', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**0 } );
    }

    if ( $from eq $OpenCloset::Donation::Status::DELIVERING && $to eq $OpenCloset::Donation::Status::RETURNED ) {
        my $msg = $self->render_to_string( 'sms/returned', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**2 } );
    }

    return 1;
}

1;

__END__

=head2 SMS BITMASK

=over

=item 2**0

신청됨|발송대기 -> 배송중

=item 2**1

반송안내문자

=item 2**2

배송중 -> 반송완료

=back

=head1 COPYRIGHT

The MIT License (MIT)

Copyright (c) 2016 열린옷장

=cut
