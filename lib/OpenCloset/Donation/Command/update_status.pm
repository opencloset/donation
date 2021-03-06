package OpenCloset::Donation::Command::update_status;

use Mojo::Base 'Mojolicious::Command';

use DateTime;
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

    if ( $from eq $DELIVERING ) {
        if ( $to eq $DELIVERED ) {
            $self->delivering2delivered();
        }
    }
    elsif ( $from eq $DELIVERED ) {
        if ( $to eq $DO_NOT_RETURN ) {
            $self->delivered2donotreturn();
        }
    }
    elsif ( $from eq $RETURN_REQUESTED ) {
        if ( $to eq $RETURNING ) {
            $self->returnrequested2returning();
        }
    }
    elsif ( $from eq $RETURNING ) {
        if ( $to eq $RETURNED ) {
            $self->returning2returned();
        }
    }
}

=head2 delivering2delivered

배송중(delivering) 상태의 item 을 체크해서 배송이 완료되었다면 배송완료(delivered) 로 변경합니다

30분마다

=cut

sub delivering2delivered {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => $DELIVERING } );
    while ( my $row = $rs->next ) {
        my $waybill = $row->waybill;
        next unless $waybill;

        my $tracker = Parcel::Track->new( $driver, $row->waybill );
        my $result = $tracker->track;
        next unless $result;

        my $latest = pop @{ $result->{descs} };
        next unless $latest =~ /배달완료/;

        $self->app->update_status( $row, $DELIVERED );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $DELIVERING, $DELIVERED;
    }
}

=head2 returnrequested2returning

반송신청(return-requested) 과 반송중(returning) 상태의 item 을 체크해서 반품배송장을 저장하고 반송중(returning)으로 변경합니다

30분마다

=cut

sub returnrequested2returning {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => { -in => [ $RETURN_REQUESTED, $RETURNING ] } } );
    while ( my $row = $rs->next ) {
        my $waybill = $row->waybill;
        next unless $waybill;

        my $return_waybill = $row->return_waybill;
        next if $return_waybill;

        my $tracker = Parcel::Track->new( $driver, $row->waybill );
        my $result = $tracker->track;
        next unless $result;

        my $html = shift @{ $result->{htmls} ||= [] };
        ($return_waybill) = $html =~ /반품:(\d+)/;
        return unless $return_waybill;

        $row->update( { return_waybill => $return_waybill } );
        $self->app->update_status( $row, $RETURNING );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $RETURN_REQUESTED,
            $RETURNING;
    }
}

=head2 returning2returned

반송중(returning) 상태의 item 을 체크해서 배송이 완료되었다면 반송완료(returned) 로 변경합니다

1시간마다

=cut

sub returning2returned {
    my $self = shift;

    my $schema = $self->app->schema;
    my $driver = 'KR::CJKorea';
    my $rs     = $schema->resultset('DonationForm')->search( { status => $RETURNING } );
    while ( my $row = $rs->next ) {
        my $return_waybill = $row->return_waybill;
        next unless $return_waybill;

        my $tracker = Parcel::Track->new( $driver, $row->return_waybill );
        my $result = $tracker->track;
        next unless $result;

        my $latest = pop @{ $result->{descs} };
        next unless $latest =~ /배달완료/;

        $self->app->update_status( $row, $RETURNED );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $RETURNING, $RETURNED;
    }
}

=head2 delivered2donotreturn

2주이상 배송완료(delivered) 상태인 item 을 반송안함(do-not-return) 으로 변경합니다

24시간마다

=cut

sub delivered2donotreturn {
    my $self = shift;

    my $dt = DateTime->now;
    $dt->subtract( days => 14 );

    my $parser = $self->app->schema->storage->datetime_parser;
    my $rs     = $self->app->schema->resultset('DonationForm')->search(
        {
            status      => $DELIVERING,
            update_date => { '<' => $parser->format_datetime($dt) }
        }
    );

    while ( my $row = $rs->next ) {
        $row->update( { status => $DO_NOT_RETURN } );
        printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $DELIVERING, $DO_NOT_RETURN;
    }
}

1;
