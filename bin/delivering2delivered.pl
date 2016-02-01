#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use IO::Socket::SSL qw( SSL_VERIFY_NONE );
use Parcel::Track;

use OpenCloset::Schema;

my $config = require 'donation.conf';
my $conf   = $config->{database};
my $schema = OpenCloset::Schema->connect(
    { dsn => $conf->{dsn}, user => $conf->{user}, password => $conf->{pass}, %{ $conf->{opts} } } );

my $driver = 'KR::CJKorea';
my $rs     = $schema->resultset('DonationForm')->search( { status => 'delivering' } );
my $http   = HTTP::Tiny->new( SSL_options => { SSL_verify_mode => SSL_VERIFY_NONE } );
while ( my $row = $rs->next ) {
    my $waybill = $row->waybill;
    next unless $waybill;

    my $uri = Parcel::Track->new( $driver, $row->waybill )->uri;
    print "GET $uri\n";
    my $res = $http->get($uri);
    unless ( $res->{success} ) {
        print STDERR "  ERROR: $res->{status}\n";
        print STDERR "  ERROR: $res->{reason}\n";
        print STDERR "  ERROR: $res->{content}\n";
        next;
    }
}
