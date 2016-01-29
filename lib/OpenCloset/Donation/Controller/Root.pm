package OpenCloset::Donation::Controller::Root;
use Mojo::Base 'Mojolicious::Controller';

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 add

    # add
    GET /new

=cut

sub add {
}

=head2 create

    # create
    POST /

=cut

sub create {
    my $self = shift;
    my $v    = $self->validation;

    $v->required('name');
    $v->optional('ever-sent');
    $v->optional('birth-date')->like(qr/\d{4}-\d{2}-\d{2}/);    # YYYY-mm-dd
    $v->optional('gender');
    $v->required('phone')->like(qr/^01[0-9]{9}$/);
    $v->required('email')->email;
    $v->required('address1');
    $v->required('address2');
    $v->required('address3');
    $v->optional('category');
    $v->optional('quantity');
    $v->optional('terms');
    $v->optional('talent-donation');
    $v->optional('talent');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $name            = $v->param('name');
    my $ever_sent       = $v->param('ever-sent');
    my $birth_date      = $v->param('birth-date');
    my $gender          = $v->param('gender');
    my $phone           = $v->param('phone');
    my $email           = $v->param('email');
    my $address1        = $v->param('address1');
    my $address2        = $v->param('address2');
    my $address3        = $v->param('address3');
    my $categories      = $v->every_param('category');
    my $quantity        = $v->param('quantity');
    my $terms           = $v->param('terms');
    my $talent_donation = $v->param('talent-donation');
    my $talent          = $v->param('talent');

    my $form = $self->schema->resultset('DonationForm')->create(
        {
            name            => $name,
            ever_sent       => $ever_sent,
            birth_date      => $birth_date,
            gender          => $gender,
            phone           => $phone,
            email           => $email,
            address1        => $address1,
            address2        => $address2,
            address3        => $address3,
            category        => join( '|', @$categories ),
            quantity        => $quantity,
            terms           => $terms,
            talent_donation => $talent_donation,
            talent          => $talent
        }
    );

    return $self->error( 500, 'Failed to create a donation' ) unless $form;

    $self->flash( name => $name );
    $self->redirect_to('done');
}

=head2 done

    # done
    GET /done

=cut

sub done {
    my $self = shift;
    my $name = $self->flash('name') || '';

    return $self->redirect_to('add') unless $name;

    $self->render( name => $name );
}

1;
