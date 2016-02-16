#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Encode qw/decode_utf8/;
use Parcel::Track;

use OpenCloset::Donation::Status;
use OpenCloset::Schema;

binmode STDOUT, ':utf8';

my $config = require 'donation.conf';
my $conf   = $config->{database};
my $schema = OpenCloset::Schema->connect( { dsn => $conf->{dsn}, user => $conf->{user}, password => $conf->{pass}, %{ $conf->{opts} } } );

my $driver = 'KR::CJKorea';
my $rs = $schema->resultset('DonationForm')->search( { status => $OpenCloset::Donation::Status::DELIVERING } );
while ( my $row = $rs->next ) {
    my $waybill = $row->waybill;
    next unless $waybill;

    my $tracker = Parcel::Track->new( $driver, $row->waybill );
    my $result = $tracker->track;
    next unless $result;

    my $latest = decode_utf8( pop @{ $result->{descs} } );
    next unless $latest =~ /배달완료/;

    $row->update( { status => $OpenCloset::Donation::Status::DELIVERED } );
    printf "[%d] %s: %s -> %s\n", $row->id, $row->name, $OpenCloset::Donation::Status::DELIVERING, $OpenCloset::Donation::Status::DELIVERED;
}
