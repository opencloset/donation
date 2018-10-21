use utf8;
use strict;
use warnings;
use DateTime;
use Encode qw/decode_utf8/;
use Getopt::Long;
use Pod::Usage;

use OpenCloset::Schema;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $config = require 'donation.conf' or die "Not found config: $!";
my $db = $config->{database};

my $schema = OpenCloset::Schema->connect(
    {
        dsn      => $db->{dsn},
        user     => $db->{user},
        password => $db->{pass},
        %{ $db->{opts} },
    }
);

my %options;
GetOptions(
    \%options,
    "--help",
    "--name|n=s",
    "--desc|d=s",
    "--sponsor|s=s",
    "--year|y=i",
    "--nth=i",
    "--start_date|S=s",
    "--end_date|E=s"
);

run( \%options, @ARGV );

sub run {
    my ( $opts ) = @_;
    pod2usage(0) if $opts->{help};
    pod2usage(0) unless $opts->{name};

    my $name       = decode_utf8($opts->{name});
    my $desc       = decode_utf8($opts->{desc} || '');
    my $sponsor    = decode_utf8($opts->{sponsor} || '');
    my $year       = $opts->{year} || (localtime)[5] + 1900; # this year
    my $nth        = $opts->{nth} || 1;
    my $start_date = $opts->{start_date} || DateTime->today(time_zone => 'Asia/Seoul')->ymd;
    my $end_date   = $opts->{end_date};

    # prevent Use of uninitialized value warn
    my $date_s = $start_date || '';
    my $date_e = $end_date   || '';

    printf(<<EOL, $name, $desc, $sponsor, $year, $nth, $date_s, $date_e);
name       : %s
desc       : %s
sponsor    : %s
year       : %d
nth        : %d
start_date : %s
end_date   : %s

EOL

    print "Continue? [Y/n] ";
    my $answer = <STDIN>;
    chomp $answer;
    $answer = 'y' if $answer eq '';
    unless ($answer =~ m/y/i) {
        print "aborted\n";
        exit;
    }

    my $event = $schema->resultset('Event')->create({
        name       => $name,
        desc       => $desc,
        sponsor    => $sponsor,
        year       => $year,
        nth        => $nth,
        start_date => $start_date,
        end_date   => $end_date
    });

    die "Failed to create a new event" unless $event;

    print "\n[OK] a new event created\n\n";
    print "$event\n";
};

__END__

=encoding utf8

=head1 NAME

add_event.pl - insert a new row to event table

=head1 SYNOPSIS

    $ script/add_event.pl
      * is required

        --help|h          print this help.
      * --name|n          name of event.
        --desc|d          description.
        --sponsor         sponsor name
        --year|y          if not present, this year is default.
        --nth             nth rounds.
        --start_date|S    if not present, today. TZ: Asia/Seoul
        --end_date|E

=cut
