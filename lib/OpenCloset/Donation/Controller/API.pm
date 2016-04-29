package OpenCloset::Donation::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

use HTTP::Tiny;

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
    $v->optional('alteration-at');
    $v->optional('cost')->like(qr/^\d*$/);
    $v->optional('assign-date')->like(qr/^\d{4}-\d{2}-\d{2}$/);
    $v->optional('pickup-date')->like(qr/^\d{4}-\d{2}-\d{2}$/);

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

    my $done          = $v->param('done');
    my $alteration_at = $v->param('alteration-at');
    my $cost          = $v->param('cost');
    my $assign_date   = $v->param('assign-date');
    my $pickup_date   = $v->param('pickup-date');

    $r->update(
        {
            done          => $done,
            alteration_at => $alteration_at,
            cost          => $cost,
            assign_date   => $assign_date,
            pickup_date   => $pickup_date,
        }
    );

    $self->render( json => { $r->get_columns } );
}

1;
