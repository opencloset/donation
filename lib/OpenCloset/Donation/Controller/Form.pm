package OpenCloset::Donation::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 list

    # forms
    GET /forms

=cut

sub list {
    my $self  = shift;
    my $forms = $self->schema->resultset('DonationForm')->search;

    $self->render( forms => $forms );
}

=head2 form

    # form
    GET /forms/:id

=cut

sub form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    $self->render( form => $form );
}

1;
