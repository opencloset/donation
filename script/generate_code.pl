#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Getopt::Long;
use Math::Fleximal;
use Pod::Usage;

use OpenCloset::Schema;
use OpenCloset::Constants::Category;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $config = require 'donation.conf' or die "Not found config: $!";

my %options;
GetOptions( \%options, "--help", "--list", "--save" );

run( \%options, $config, @ARGV );

sub run {
    my ( $opts, $conf, $category, $quantity ) = @_;
    return pod2usage(0) if $opts->{help};
    return print_list() if $opts->{list};
    return pod2usage(0) unless $category;
    return pod2usage(0) unless $quantity;

    my $db     = $conf->{database};
    my $schema = OpenCloset::Schema->connect(
        {
            dsn => $db->{dsn}, user => $db->{user}, password => $db->{pass},
            %{ $db->{opts} },
        }
    );

    my $clothes_code = $schema->resultset('ClothesCode')->find( { category => $category } );
    die "의류코드를 찾을 수 없습니다: $category" unless $clothes_code;
    die "수량이 잘못되었습니다: $quantity" unless $quantity =~ /^\d+$/;

    my $code = substr $clothes_code->code, 1;
    my $category_prefix = substr $code, 0, 1;
    my $rest = substr $code, 1;

    my $last;
    my @digits = ( 0 .. 9, 'A' .. 'Z' );
    my $number = Math::Fleximal->new( $rest, \@digits );
    for ( 0 .. $quantity - 1 ) {
        my $fleximal = Math::Fleximal->new($_)->change_flex( \@digits )->add($number)->add( $number->one )->to_str;
        my $code     = sprintf( "%s%03s", $category_prefix, $fleximal );
        my @decimal  = map { Math::Fleximal->new( $_, \@digits )->base_10 } split //, $code;
        printf( "%s,%02d%02d-%02d%02d\n", $code, @decimal );
        $last = $code;
    }

    return unless $opts->{save};

    ## save last code
    $clothes_code->update( { code => sprintf( '%05s', $last ) } );
    print STDERR "-------------------------------------------------\n";
    print STDERR "'-']/ $category 의류코드가 갱신되었습니다 => $last\n";
}

sub print_list {
    print join( ", ", @OpenCloset::Constants::Category::ALL ), "\n";
    return;
}

__END__

=encoding utf8

=head1 NAME

generate_code.pl - clothes code generator

=head1 SYNOPSIS

    $ script/generate_code.pl jacket 10
    $ script/generate_code.pl jacket 10 --save
    $ script/generate_code.pl jacket 10 --save > jacket.csv

    $ script/generate_code.pl --list
    $ script/generate_code.pl --help

=head1 DESCRIPTION

C<--save> 옵션은 last_code 를 업데이트 합니다.

=cut
