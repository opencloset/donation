package OpenCloset::Donation::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use DateTime;
use HTTP::Tiny;
use Try::Tiny;

use OpenCloset::Common::Clothes;
use OpenCloset::Constants::Category;
use OpenCloset::Constants::Status qw/$RENTABLE $RENTALESS $RESERVATION $CLEANING $REPAIR $RETURNED $LOST $DISCARD/;

## repair_clothes.done
our $DONE_RESIZED   = 1;
our $DONE_COMPLETED = 2;
our $DONE_RESET     = 3;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 create_sms

    # sms.create
    POST /sms

=cut

sub create_sms {
    my $self = shift;

    my $v = $self->validation;
    $v->required('to')->like(qr/^01\d{9}/);
    $v->required('text');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $to   = $v->param('to');
    my $text = $v->param('text');

    my $sms = $self->sms( $to, $text );
    return $self->error( 500, 'Failed to send a sms' ) unless $sms;

    $self->render( json => { $sms->get_columns } );
}

=head2 create_user

    # user.create
    POST /users

=cut

sub create_user {
    my $self = shift;

    my $v = $self->validation;
    $v->required('form_id');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $id = $v->param('form_id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $cookie = $self->cookie('opencloset');
    return $self->error( 401, "Authorize required" ) unless $cookie;

    my %params = map { $_ => $form->$_ } qw/name phone email gender/;
    $params{address2} = $form->address1 || '';
    $params{address3} = $form->address2 || '';
    $params{address4} = $form->address3 || '';
    $params{birth} = substr( $form->birth_date || '', 0, 4 );

    if ( exists $params{gender} ) {
        my $gender = $params{gender};
        if ( $gender == 1 ) {
            $params{gender} = 'male';
        }
        elsif ( $gender == 2 ) {
            $params{gender} = 'female';
        }
        else {
            $params{gender} = 'unisex';
        }
    }

    my $http = HTTP::Tiny->new;
    my $root = $self->config->{opencloset}{root};
    my $res  = $http->post_form( "$root/api/user.json", \%params, { headers => { cookie => "opencloset=$cookie" } } );

    $self->res->code( $res->{status} );
    $self->render( text => $res->{content} || $res->{reason} );
}

=head2 code

    GET /clothes/code?category=:category

=cut

sub code {
    my $self     = shift;
    my $category = $self->param('category');

    return $self->error( '400', 'category param required' ) unless $category;

    my $code = $self->generate_code($category);
    return $self->error( '404', 'Not found category' ) unless $code;

    $self->render( json => { category => $category, code => $code } );
}

=head2 repair_clothes

    # clothes.repair
    PUT /clothes/repair/:code

=cut

sub repair_clothes {
    my $self = shift;
    my $code = $self->param('code');

    my $v = $self->validation;
    $v->optional('done');
    $v->optional('alteration_at');
    $v->optional('comment');
    $v->optional('cost')->like(qr/^\d*$/);
    $v->optional('assign_date')->like(qr/^\d{4}-\d{2}-\d{2}$/);
    $v->optional('pickup_date')->like(qr/^\d{4}-\d{2}-\d{2}$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $clothes = $self->schema->resultset('Clothes')->find( { code => $code } );
    return $self->error( 404, "Clothes not found: $code" ) unless $clothes;

    my $r = $self->schema->resultset('RepairClothes')->find_or_create( { clothes_code => $clothes->code } );

    unless ($r) {
        my $err = "Couldn't find or create repair clothes";
        $self->log->error($err);
        return $self->error( 500, $err );
    }

    my $input = $v->input;
    map { delete $input->{$_} } qw/name pk value/; # delete x-editable params

    if ( exists $input->{done} && $input->{done} == $DONE_COMPLETED && !exists $input->{pickup_date} ) {
        $input->{pickup_date} = DateTime->now;
    }
    elsif ( exists $input->{done} && $input->{done} == $DONE_RESET ) {
        $r->update(
            {
                alteration_at => undef,
                cost          => 0,
                done          => undef,
                comment       => undef,
                assign_date   => undef,
                pickup_date   => undef,
            }
        );
    }

    if ( $input->{alteration_at} ) {
        my $status_id = $clothes->status_id;
        if ( "$RENTABLE $RENTALESS $RESERVATION $CLEANING $RETURNED" =~ m/\b$status_id\b/ ) {
            $clothes->update( { status_id => $REPAIR } );
        }
    }

    $r->update($input);
    $self->render( json => { $r->get_inflated_columns } );
}

=head2 suggestion_resize

    # clothes.resize.suggestion
    GET /clothes/:code/suggestion

=head3 params

=over

=item stretch

unsigned int(cm)

=item has_tuck

boolean(1 or 0)

=item has_dual_tuck

boolean(1 or 0)

=back

=head3 Supports Categories

=over

=item PANTS

=item SKIRT

=back

=cut

sub suggestion_resize {
    my $self = shift;
    my $code = $self->param('code');

    my $stretch       = $self->param('stretch') || 0;
    my $has_tuck      = $self->param('has_tuck');
    my $has_dual_tuck = $self->param('has_dual_tuck');
    my $opts          = {
        stretch       => $stretch,
        has_tuck      => $has_tuck,
        has_dual_tuck => $has_dual_tuck
    };

    my $rs = $self->schema->resultset('Clothes')->find( { code => $code } );
    return $self->error( 404, "Clothes not found: $code" ) unless $rs;

    my $category = $rs->category;
    return $self->error( 400, "Not supported category: $category" ) unless "$JACKET $PANTS $SKIRT" =~ m/\b$category\b/;

    my $clothes     = OpenCloset::Common::Clothes->new( clothes => $rs );
    my $top         = $rs->top;
    my $bottom      = $rs->bottom;
    my $diff_bottom = '';
    my $diff_top    = '';
    my $messages;

    my $r = $self->schema->resultset('RepairClothes')->find( { clothes_code => $rs->code } );
    if ( $r && $r->done ) {
        $diff_bottom = $self->clothesDiff($bottom);
        $diff_top    = $self->clothesDiff($top);
    }
    else {
        my $suggestion = $clothes->suggest_repair_size($opts);
        $messages    = $suggestion->{messages};
        $diff_bottom = $self->clothesDiff( $bottom, $suggestion->{bottom} );
        $diff_top    = '';
        if ($top) {
            $diff_top = $self->clothesDiff( $top, $suggestion->{top} );
        }
    }

    $self->render( json => { diff => { top => $diff_top, bottom => $diff_bottom }, messages => $messages || {} } );
}

=head2 update_resize

    # clothes.resize.update
    PUT /clothes/:code/suggestion

=head3 params

=over

=item stretch

unsigned int(cm)

=item has_tuck

boolean(1 or 0)

=item has_dual_tuck

boolean(1 or 0)

=back

=head3 Supports Categories

=over

=item PANTS

=item SKIRT

=back

=cut

our %HANGUL_PART_MAP = (
    '허벅지' => 'thigh',
    '밑단'    => 'cuff',
    '허리'    => 'waist',
    '길이'    => 'length',
    '치마폭' => 'unknown', # 이게 뭐지?
    '윗배'    => 'topbelly',
    '팔길이' => 'arm',
);

sub update_resize {
    my $self = shift;
    my $code = $self->param('code');

    my $stretch       = $self->param('stretch') || 0;
    my $has_tuck      = $self->param('has_tuck');
    my $has_dual_tuck = $self->param('has_dual_tuck');
    my $opts          = {
        stretch       => $stretch,
        has_tuck      => $has_tuck,
        has_dual_tuck => $has_dual_tuck
    };

    my $ignore = $self->every_param('ignore');
    my @ignore = map { $HANGUL_PART_MAP{$_} } @$ignore;

    my $rs = $self->schema->resultset('Clothes')->find( { code => $code } );
    return $self->error( 404, "Clothes not found: $code" ) unless $rs;

    my $category = $rs->category;
    return $self->error( 400, "Not supported category: $category" ) unless "$JACKET $PANTS $SKIRT" =~ m/\b$category\b/;

    my $clothes    = OpenCloset::Common::Clothes->new( clothes => $rs );
    my $top        = $rs->top;
    my $bottom     = $rs->bottom;
    my $suggestion = $clothes->suggest_repair_size($opts);

    for my $ignore (@ignore) {
        delete $suggestion->{bottom}{$ignore};
        delete $suggestion->{top}{$ignore};
    }

    my $r = $self->schema->resultset('RepairClothes')->find_or_create( { clothes_code => $rs->code } );
    unless ($r) {
        my $err = "Couldn't find or create repair clothes";
        $self->log->error($err);
        return $self->error( 500, $err );
    }

    ## transaction
    my $guard = $self->schema->txn_scope_guard;
    try {
        $bottom->update( $suggestion->{bottom} ) if $bottom;
        $top->update( $suggestion->{top} )       if $top;
        $r->update( { done => $DONE_RESIZED } );
        $guard->commit;
    }
    catch {
        my $err = $_;
        $self->log->error("Transaction error: clothes.resize.update");
        $self->log->error($err);

        return $self->error( 500, $err );
    };

    $self->render(
        json => {
            top    => $top    ? { $top->get_inflated_columns }    : {},
            bottom => $bottom ? { $bottom->get_inflated_columns } : {},
            repair => { $r->get_inflated_columns }
        }
    );
}

=head2 create_suit

    # suit.create
    POST /suit

=cut

sub create_suit {
    my $self = shift;

    my $v = $self->validation;
    $v->required('code_top');
    $v->required('code_bottom');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $cookie = $self->cookie('opencloset');
    return $self->error( 401, "Authorize required" ) unless $cookie;

    my $input = $v->input;
    map { $input->{$_} =~ s/^0// } keys %$input;

    my $http = HTTP::Tiny->new;
    my $root = $self->config->{opencloset}{root};
    my $res  = $http->post_form( "$root/api/suit.json", $input, { headers => { cookie => "opencloset=$cookie" } } );

    $self->res->code( $res->{status} );
    $self->render( text => $res->{content} || $res->{reason} );
}

=head2 clothes_tags

    # clothes.code.tags
    GET /clothes/:code/tags

=cut

sub clothes_tags {
    my $self = shift;
    my $code = $self->param('code');

    my $clothes = $self->schema->resultset('Clothes')->find( { code => sprintf( "%05s", $code ) } );
    return $self->error( 404, "Clothes not found: $code" ) unless $clothes;

    $code =~ s/^0//;
    my %status = $clothes->status->get_columns;
    $status{rent} = $status{id} == 2;
    my @tags;
    my $tags = $clothes->tags;
    while ( my $tag = $tags->next ) {
        push @tags, { $tag->get_columns };
    }

    my $suit_code;
    if ( $code =~ m/^[J]/ ) {
        my $bottom = $clothes->bottom;
        $suit_code = substr $bottom->code, 1 if $bottom;
    }
    elsif ( $code =~ m/^[PK]/ ) {
        my $top = $clothes->top;
        $suit_code = substr $top->code, 1 if $top;
    }

    $self->render( json => { code => $code, status => \%status, tags => \@tags, suit => { code => $suit_code } } );
}

=head2 update_clothes

    # clothes.update
    PUT /clothes

=cut

sub update_clothes {
    my $self = shift;

    my $v = $self->validation;
    $v->required('code')->like(qr/^[A-Z0-9]{4,5}$/);
    $v->required('status_id')->like(qr/^[0-9]+$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $codes     = $v->every_param('code');
    my $status_id = $v->param('status_id');
    my $status    = $self->schema->resultset('Status')->find( { id => $status_id } );

    return $self->error( 400, "Not found status: $status_id" ) unless $status;
    my @codes = map { sprintf( '%05s', $_ ) } @$codes;
    my $clothes = $self->schema->resultset('Clothes')->search( { code => { -in => \@codes } } );
    $clothes->update( { status_id => $status_id } );
    ## 분실, 폐기일때에 의류의 모든 태그를 제거 #72
    ## 분실, 폐기일때에 셋트의류 해제 #73
    if ( $status_id == $LOST || $status_id == $DISCARD ) {
        while ( my $c = $clothes->next ) {
            $c->delete_related('clothes_tags');
            $c->delete_related('suit_code_top');
            $c->delete_related('suit_code_bottom');
        }
    }

    $self->render( json => { code => $codes, status => { $status->get_columns } } );
}

=head2 create_clothes_tag

    # clothes.create.tag
    POST /clothes/tags

=cut

sub create_clothes_tag {
    my $self = shift;

    my $v = $self->validation;
    $v->required('code')->like(qr/^[A-Z0-9]{4,5}$/);
    $v->required('tag_id')->like(qr/^[0-9]+$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $codes  = $v->every_param('code');
    my $tag_id = $v->param('tag_id');
    my $tag    = $self->schema->resultset('Tag')->find( { id => $tag_id } );

    return $self->error( 400, "Not found status: $tag_id" ) unless $tag;
    my @codes = map { sprintf( '%05s', $_ ) } @$codes;
    my $clothes = $self->schema->resultset('Clothes')->search( { code => { -in => \@codes } } );
    while ( my $c = $clothes->next ) {
        $c->find_or_create_related( 'clothes_tags', { tag_id => $tag_id } );
    }

    $self->render( json => { code => $codes, tag => { $tag->get_columns } } );
}

=head2 delete_clothes_tag

    # clothes.delete.tag
    DELETE /clothes/tags

=cut

sub delete_clothes_tag {
    my $self = shift;

    my $v = $self->validation;
    $v->required('code')->like(qr/^[A-Z0-9]{4,5}$/);
    $v->required('tag_id')->like(qr/^[0-9]+$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $codes  = $v->every_param('code');
    my $tag_id = $v->param('tag_id');
    my $tag    = $self->schema->resultset('Tag')->find( { id => $tag_id } );

    return $self->error( 400, "Not found status: $tag_id" ) unless $tag;
    my @codes = map { sprintf( '%05s', $_ ) } @$codes;
    my $clothes = $self->schema->resultset('Clothes')->search( { code => { -in => \@codes } } );
    while ( my $c = $clothes->next ) {
        $c->delete_related( 'clothes_tags', { tag_id => $tag_id } );
    }

    $self->render( json => { code => $codes, tag => { $tag->get_columns } } );
}

1;
