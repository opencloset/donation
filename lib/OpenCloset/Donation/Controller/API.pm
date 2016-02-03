package OpenCloset::Donation::Controller::API;
use Mojo::Base 'Mojolicious::Controller';

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 create_sms

    # sms.create
    POST /api/sms

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

    $self->render( json => { $sms->columns } );
}

1;
