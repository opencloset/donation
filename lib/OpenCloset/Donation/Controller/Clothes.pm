package OpenCloset::Donation::Controller::Clothes;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 index

    GET /forms/:id/clothes

=cut

sub index {
    my $self = shift;
    my $form = $self->stash('form');

    my $user = $self->schema->resultset('User')->find( { email => $form->email } );
    unless ($user) {
        my $user_info = $self->schema->resultset('UserInfo')->find( { phone => $form->phone } );
        $user = $user_info->user if $user_info;
    }

    return $self->error( 404, "User not found" ) unless $user;

    my %categories;
    my $donations = $user->donations( undef, { order_by => { -desc => 'create_date' } } );
    while ( my $donation = $donations->next ) {
        my $clothes = $donation->clothes;
        while ( my $row = $clothes->next ) {
            my $category = $row->category;
            $categories{$category}++;
        }
    }

    $self->render( user => $user, categories => \%categories, donations => $donations->reset );
}

=head2 add

    GET /forms/:id/clothes/new

=cut

sub add {
    my $self = shift;
    my $form = $self->stash('form');

    my $user = $self->schema->resultset('User')->find( { email => $form->email } );
    unless ($user) {
        my $user_info = $self->schema->resultset('UserInfo')->find( { phone => $form->phone } );
        $user = $user_info->user if $user_info;
    }

    return $self->error( 404, "User not found" ) unless $user;
}

=head2 create

    POST /forms/:id/clothes

=cut

sub create {
    my $self = shift;
}

1;
