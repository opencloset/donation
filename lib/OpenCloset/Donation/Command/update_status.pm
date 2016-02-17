package OpenCloset::Donation::Command::update_status;

use Mojo::Base 'Mojolicious::Command';

use OpenCloset::Donation::Status;
use Parcel::Track;

has description => 'Update status [FROM] to [TO] if ready';
has usage       => "Usage: APPLICATION update_status [FROM] [TO]\n";

binmode STDOUT, ':utf8';

=encoding utf-8

=head1 NAME

OpenCloset::Donation::Command::update_status

=head1 SYNOPSIS

    $ MOJO_CONFIG=/path/to/donation.conf ./script/donation update_status delivering delivered

=head1 METHODS

=head2 run

=cut

sub run {
    my ( $self, $from, $to ) = @_;

    my $v = $self->app->validation;
    $v->input( { from => $from, to => $to } );
    $v->required('from')->in(@OpenCloset::Donation::Status::ALL);
    $v->required('to')->in(@OpenCloset::Donation::Status::ALL);

    if ( $v->has_error ) {
        my @all = @OpenCloset::Donation::Status::ALL;
        shift @all;

        say $self->usage;
        say 'Available status: ' . join( ', ', @all );
        return;
    }

    say "[$from] -> [$to]\n";

    if ( $from eq $OpenCloset::Donation::Status::DELIVERING ) {
        if ( $to eq $OpenCloset::Donation::Status::DELIVERED ) {
            $self->delivering2delivered();
        }
    }
    elsif ( $from eq $OpenCloset::Donation::Status::RETURN_REQUESTED ) {
        if ( $to eq $OpenCloset::Donation::Status::RETURNING ) {
            $self->returnrequested2returning();
        }
    }
    elsif ( $from eq $OpenCloset::Donation::Status::RETURNING ) {
        if ( $to eq $OpenCloset::Donation::Status::RETURNED ) {
            $self->returning2returned();
        }
    }
}

=head2 delivering2delivered

배송중(delivering) 상태의 item 을 체크해서 배송이 완료되었다면 배송완료(delivered) 로 변경합니다

=cut

sub delivering2delivered {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => $OpenCloset::Donation::Status::DELIVERING } );
    while ( my $row = $rs->next ) {
        my $waybill = $row->waybill;
        next unless $waybill;

        my $tracker = Parcel::Track->new( $driver, $row->waybill );
        my $result = $tracker->track;
        next unless $result;

        my $latest = pop @{ $result->{descs} };
        next unless $latest =~ /배달완료/;

        $self->app->update_status( $row, $OpenCloset::Donation::Status::DELIVERED );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $OpenCloset::Donation::Status::DELIVERING, $OpenCloset::Donation::Status::DELIVERED;
    }
}

=head2 returnrequested2returning

반송요청(return-requested) 상태의 item 을 체크해서 반품배송장을 저장하고 반송중(returning)으로 변경합니다

=cut

sub returnrequested2returning {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => $OpenCloset::Donation::Status::RETURN_REQUESTED } );
    while ( my $row = $rs->next ) {
        my $waybill = $row->waybill;
        next unless $waybill;

        my $tracker = Parcel::Track->new( $driver, $row->waybill );
        my $result = $tracker->track;
        next unless $result;

        my $html = shift @{ $result->{htmls} ||= [] };
        my ($return_waybill) = $html =~ /반품:(\d+)/;
        return unless $return_waybill;

        $row->update( { return_waybill => $return_waybill } );
        $self->app->update_status( $row, $OpenCloset::Donation::Status::RETURNING );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $OpenCloset::Donation::Status::RETURN_REQUESTED,
            $OpenCloset::Donation::Status::RETURNING;
    }
}

=head2 returning2returned

반송중(returning) 상태의 item 을 체크해서 배송이 완료되었다면 반송완료(returned) 로 변경합니다

=cut

sub returning2returned {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => $OpenCloset::Donation::Status::RETURNING } );
    while ( my $row = $rs->next ) {
        my $return_waybill = $row->return_waybill;
        next unless $return_waybill;

        my $tracker = Parcel::Track->new( $driver, $row->return_waybill );
        my $result = $tracker->track;
        next unless $result;

        my $latest = pop @{ $result->{descs} };
        next unless $latest =~ /배달완료/;

        $self->app->update_status( $row, $OpenCloset::Donation::Status::RETURNED );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $OpenCloset::Donation::Status::RETURNING, $OpenCloset::Donation::Status::RETURNED;
    }
}

1;
