package OpenCloset::Donation::Controller::Clothes;
use Mojo::Base 'Mojolicious::Controller';

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 add

    # clothes.add
    GET /users/:id/donations/:donation_id/clothes/new

=cut

sub add { }

=head2 create

    # clothes.create
    POST /users/:id/donations/:donation_id/clothes

=cut

sub create { }

1;
