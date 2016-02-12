#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use DateTime;

use OpenCloset::Donation::Status;
use OpenCloset::Schema;

binmode STDOUT, ':utf8';

my $config = require 'donation.conf';
my $conf   = $config->{database};
my $schema = OpenCloset::Schema->connect(
    {
        dsn => $conf->{dsn}, user => $conf->{user}, password => $conf->{pass},
        %{ $conf->{opts} }
    }
);

my $dt = DateTime->now;
$dt->subtract( days => 14 );

my $parser = $schema->storage->datetime_parser;
my $rs     = $schema->resultset('DonationForm')->search(
    {
        status      => $OpenCloset::Donation::Status::DELIVERING,
        update_date => { '<' => $parser->format_datetime($dt) }
    }
);

while ( my $row = $rs->next ) {
    $row->update( { status => $OpenCloset::Donation::Status::DO_NOT_RETURN } );
    printf "[%d] %s: %s -> %s\n", $row->id, $row->name,
        $OpenCloset::Donation::Status::DELIVERING,
        $OpenCloset::Donation::Status::DO_NOT_RETURN;
}
