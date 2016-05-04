package OpenCloset::Donation::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use HTTP::Tiny;
use Try::Tiny;

use OpenCloset::Clothes;
use OpenCloset::Constants::Category;

## repair_clothes.done
our $DONE_RESIZED   = 1;
our $DONE_COMPLETED = 2;

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

    $r->update($input);
    $self->render( json => { $r->get_columns } );
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
    return $self->error( 400, "Unsupported category: $category" ) unless "$PANTS $SKIRT" =~ m/\b$category\b/;

    my $suit   = $rs->suit_code_bottom;
    my $top    = $suit ? $suit->code_top : undef;
    my $bottom = $rs;

    my $clothes = OpenCloset::Clothes->new( clothes => $bottom );
    my $suggestion = $clothes->suggest_repair_size($opts);

    my $diff_bottom = $self->clothesDiff( $bottom, $suggestion->{bottom} );
    my $diff_top = '';
    if ($top) {
        $diff_top = $self->clothesDiff( $top, $suggestion->{top} );
    }

    $self->render( json => { diff => { top => $diff_top, bottom => $diff_bottom }, messages => $suggestion->{messages} } );
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

sub update_resize {
    my $self = shift;
    my $code = $self->param('code');

    my $rs = $self->schema->resultset('Clothes')->find( { code => $code } );
    return $self->error( 404, "Clothes not found: $code" ) unless $rs;

    my $category = $rs->category;
    return $self->error( 400, "Unsupported category: $category" ) unless "$PANTS $SKIRT" =~ m/\b$category\b/;

    my $stretch       = $self->param('stretch') || 0;
    my $has_tuck      = $self->param('has_tuck');
    my $has_dual_tuck = $self->param('has_dual_tuck');
    my $opts          = {
        stretch       => $stretch,
        has_tuck      => $has_tuck,
        has_dual_tuck => $has_dual_tuck
    };

    my $suit   = $rs->suit_code_bottom;
    my $top    = $suit ? $suit->code_top : undef;
    my $bottom = $rs;

    my $clothes = OpenCloset::Clothes->new( clothes => $bottom );
    my $suggestion = $clothes->suggest_repair_size($opts);

    my $r = $self->schema->resultset('RepairClothes')->find_or_create( { clothes_code => $rs->code } );
    unless ($r) {
        my $err = "Couldn't find or create repair clothes";
        $self->log->error($err);
        return $self->error( 500, $err );
    }

    ## transaction
    my $guard = $self->schema->txn_scope_guard;
    try {
        $bottom->update( $suggestion->{bottom} );
        $top->update( $suggestion->{top} ) if $top;
        $r->update( { done => $DONE_RESIZED } );
        $guard->commit;
    }
    catch {
        my $err = $_;
        $self->log->error("Transaction error: clothes.resize.update");
        $self->log->error($err);

        return $self->error( 500, $err );
    };

    $self->render( json => { top => $top ? { $top->get_columns } : {}, bottom => { $bottom->get_columns }, repair => { $r->get_columns } } );
}

1;
