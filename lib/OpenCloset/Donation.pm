package OpenCloset::Donation;
use Mojo::Base 'Mojolicious';

=head1 METHODS

=head2 startup

This method will run once at server start

=cut

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->plugin('OpenCloset::Plugin::Helpers');
    $self->secrets( [$ENV{OPENCLOSET_DONATION_SECRET} || time] );
    $self->sessions->cookie_name( $self->app->moniker );
    $self->sessions->default_expiration(86400);

    $self->_assets;
    $self->_public_routes;
    $self->_private_routes;
}

sub _assets {
    my $self = shift;

    $self->defaults( jses => [], csses => [] );
}

sub _public_routes {
    my $self = shift;
    my $r    = $self->routes;

    $r->get('/')->to( cb => sub { shift->redirect_to('add') } );

    $r->get('/new')->to('root#add')->name('add');
    $r->post('/')->to('root#create')->name('create');
}

sub _private_routes { }

1;
