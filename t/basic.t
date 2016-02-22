use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

$ENV{MOJO_CONFIG} = 'donation.conf';

my $t = Test::Mojo->new('OpenCloset::Donation');
$t->get_ok('/new')->status_is(200);

done_testing();
