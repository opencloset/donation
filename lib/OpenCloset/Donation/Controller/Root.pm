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


1;
