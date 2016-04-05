package OpenCloset::Donation::Plugin::Helpers;

use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::DOM::HTML;
use Math::Fleximal;

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

    $app->helper( status2label          => \&status2label );
    $app->helper( update_status         => \&update_status );
    $app->helper( emphasis              => \&emphasis );
    $app->helper( clothes2link          => \&clothes2link );
    $app->helper( clothes_quantity      => \&clothes_quantity );
    $app->helper( generate_code         => \&generate_code );
    $app->helper( generate_discard_code => \&generate_discard_code );
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
            qq{<span class="label label-default active status$class" title="$status" data-status="$status"><i class="fa fa-archive"></i>$str</span>});
    }
    else {
        $html->parse(qq{<span class="label label-default status$class" title="$status" data-status="$status">$str</span>});
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

=item return-requested

=item returning

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

    if ( $from eq $OpenCloset::Donation::Status::DELIVERING && $to eq $OpenCloset::Donation::Status::DELIVERED ) {
        my $msg = $self->render_to_string( 'sms/delivering2delivered', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**1 } );
    }

    if ( $from eq $OpenCloset::Donation::Status::RETURN_REQUESTED && $to eq $OpenCloset::Donation::Status::RETURNING ) {
        my $msg = $self->render_to_string( 'sms/returnrequested2returning', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**2 } );
    }

    if ( $from eq $OpenCloset::Donation::Status::RETURNING && $to eq $OpenCloset::Donation::Status::RETURNED ) {
        my $msg = $self->render_to_string( 'sms/returning2returned', format => 'txt', form => $form );
        chomp $msg;
        $self->sms( $form->phone, $msg );
        my $bitmask = $form->sms_bitmask;
        $form->update( { sms_bitmask => $bitmask | 2**3 } );
    }

    return 1;
}

=head2 emphasis($text, $search)

    %= emphasis('1234', '12');
    # <em>12</em>34

    %= emphasis('1234', '5678');
    # 1234

=cut

sub emphasis {
    my ( $self, $text, $search ) = @_;

    return '' unless $text;
    return $text unless $search;

    $text =~ s/$search/<em>$search<\/em>/g;
    return Mojo::ByteStream->new($text);
}

=head2 clothes2link($clothes, $external?)

    %= clothes2link($clothes)
    # <a href="https://staff.theopencloset.net/J001">
    #  <%= $clothes->code %>
    # </a>

    %= clothes2link($clothes, 1)
    # <a href="https://staff.theopencloset.net/J001" target="_blank">
    #  <i class="fa fa-external-link"></i>
    #  <%= $clothes->code %>
    # </a>

=cut

sub clothes2link {
    my ( $self, $clothes, $external ) = @_;
    return '' unless $clothes;

    my $code = $clothes->code;
    $code =~ s/^0//;
    my $prefix = $self->config->{opencloset}{root} . '/clothes';
    my $html   = Mojo::DOM::HTML->new;

    if ($external) {
        $html->parse(
            qq{<a href="$prefix/$code" target="_blank">
  <span class="label label-primary"><i class="fa fa-external-link"></i> $code</label>
</a>}
        );
    }
    else {
        $html->parse(qq{<a href="$prefix/$code"><span class="label label-primary">$code</label></a>});
    }

    my $tree = $html->tree;
    return Mojo::ByteStream->new( Mojo::DOM::HTML::_render($tree) );
}

=head2 clothes_quantity

    my $hashref = $self->clothes_quantity($donation);

    $hashref->{jacket};    # 4
    $hashref->{pants};     # 2
    $hashref->{tie};       # 1


=cut

sub clothes_quantity {
    my ( $self, $donation ) = @_;
    return unless $donation;

    ## SELECT category, COUNT(category) FROM clothes WHERE donation_id = 2588 GROUP BY category;
    my $rs = $donation->clothes( undef, { group_by => 'category', select => [ 'category', { count => 'category', -as => 'quantity' } ] } );

    return unless $rs->count;

    my $hashref = {};
    while ( my $row = $rs->next ) {
        my $category = $row->category;
        my $quantity = $row->get_column('quantity');
        $hashref->{$category} = $quantity;
    }

    return $hashref;
}

=head2 generate_code( $category )

    my $code = generate_code('jacket');    # JA17

WARNING: 순서대로 바코드를 사용하고 있지 않기 때문에 이거 쓰면 안됨.

=cut

sub generate_code {
    my ( $self, $category ) = @_;
    return unless $category;

    my $clothes = $self->schema->resultset('Clothes')->search(
        {
            category  => $category,
            status_id => { 'NOT IN' => [ 45, 46, 47 ] }
        },
        {
            order_by => { -desc => 'id' },
            rows     => 1,
        }
    )->next;
    return unless $clothes;

    my $code = $clothes->code;

    $code =~ s/^0//;
    my $category_prefix = substr $code, 0, 1;
    my $rest = substr $code, 1;

    my @digits = ( 0 .. 9, 'A' .. 'Z' );
    my $number = Math::Fleximal->new( $rest, \@digits );
    my $last = Math::Fleximal->new(0)->change_flex( \@digits )->add($number)->add( $number->one )->to_str;

    return sprintf( '%s%03s', $category_prefix, $last );
}

=head2 generate_discard_code( $category )

    my $discard_code = generate_discard_code('jacket');    # JA17

=cut

sub generate_discard_code {
    my ( $self, $category ) = @_;
    return unless $category;

    my $clothes_code = $self->schema->resultset('ClothesCode')->find( { category => $category } );
    return unless $clothes_code;

    my $code = $clothes_code->code;

    $code =~ s/^0//;
    my $category_prefix = substr $code, 0, 1;
    my $rest = substr $code, 1;

    my @digits = ( 0 .. 9, 'A' .. 'Z' );
    my $number = Math::Fleximal->new( $rest, \@digits );
    my $last = Math::Fleximal->new(0)->change_flex( \@digits )->add($number)->add( $number->one )->to_str;

    return sprintf( '%s%03s', $category_prefix, $last );
}

1;

__END__

=head2 SMS BITMASK

=over

=item 2**0

신청됨(null)|발송대기(waiting) -> 배송중(delivering)

=item 2**1

배송중(delivering) -> 배송완료(delivered)

=item 2**2

반송신청(return-requested) -> 반송중(returning)

=item 2**3

반송중(returning) -> 반송완료(returned)

=back

=head1 COPYRIGHT

The MIT License (MIT)

Copyright (c) 2016 열린옷장

=cut
