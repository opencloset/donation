package OpenCloset::Donation::Command::delivering2delivered;

use Mojo::Base 'Mojolicious::Command';

use Parcel::Track;

use OpenCloset::Donation::Status;

has description => 'Delivering2delivered on application';
has usage       => "Usage: APPLICATION delivering2delivered [TARGET]\n";

sub run {
    my ( $self, @args ) = @_;

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

1;
