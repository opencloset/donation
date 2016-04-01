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

    my %params = map { $_ => $form->$_ } qw/name phone email/;
    $params{address2} = $form->address1 || '';
    $params{address3} = $form->address2 || '';
    $params{address4} = $form->address3 || '';
    $params{birth} = substr( $form->birth_date || '', 0, 4 );

    my $http = HTTP::Tiny->new;
    my $root = $self->config->{opencloset}{root};
    my $res  = $http->post_form( "$root/api/user.json", \%params, { headers => { cookie => "opencloset=$cookie" } } );

    $self->res->code( $res->{status} );
    $self->render( text => $res->{content} || $res->{reason} );
}

1;
