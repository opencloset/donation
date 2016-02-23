package OpenCloset::Donation;
use Mojo::Base 'Mojolicious';

use Email::Valid ();

use OpenCloset::Schema;

use version; our $VERSION = qv("v0.0.1");

has schema => sub {
    my $self = shift;
    my $conf = $self->config->{database};
    OpenCloset::Schema->connect(
        {
            dsn => $conf->{dsn}, user => $conf->{user}, password => $conf->{pass},
            %{ $conf->{opts} },
        }
    );
};

=head1 METHODS

=head2 startup

This method will run once at server start

=cut

sub startup {
    my $self = shift;

    $self->plugin('Config');
    $self->plugin('OpenCloset::Plugin::Helpers');
    $self->plugin('OpenCloset::Donation::Plugin::Helpers');

    $self->secrets( $self->config->{secrets} );
    $self->sessions->cookie_domain( $self->config->{cookie_domain} );
    $self->sessions->cookie_name('opencloset');
    $self->sessions->default_expiration(86400);

    push @{ $self->commands->namespaces }, 'OpenCloset::Donation::Command';

    $self->_assets;
    $self->_public_routes;
    $self->_private_routes;
    $self->_extend_validator;
}

sub _assets {
    my $self = shift;

    $self->defaults( jses => [], csses => [] );
}

sub _public_routes {
    my $self = shift;
    my $r    = $self->routes;

    $r->get('/')->to('root#index')->name('home');
    $r->get('/guide1')->to('root#guide1');
    $r->get('/guide2')->to('root#guide2');

    $r->get('/new')->to('root#add')->name('add');
    $r->post('/')->to('root#create')->name('create');
    $r->get('/done')->to('root#done')->name('done');

    $r->get('/forms/:id/return')->to('form#sendback')->name('form.return');
    $r->post('/forms/:id/return')->to('form#create_sendback');
    $r->get('/forms/:id/return/done')->to('form#sendback_done')->name('form.return.done');
}

sub _private_routes {
    my $self = shift;
    my $r    = $self->routes;
    my $form = $r->under('/forms')->to('user#auth')->name('auth');
    my $sms  = $r->under('/sms')->to('user#auth');
    my $user = $r->under('/user')->to('user#auth');

    $form = $form->under('/')->to('form#prefetch');
    $form->get('/')->to('form#list')->name('forms');
    $form->get('/:id')->to('form#form')->name('form');
    $form->any( [ 'POST', 'PUT' ] => '/:id' )->to('form#update_form')->name('form.update');

    $sms->post('/')->to('API#create_sms')->name('sms.create');
    $user->post('/')->to('API#create_user')->name('user.create');
}

sub _extend_validator {
    my $self = shift;

    $self->validator->add_check(
        email => sub {
            my ( $v, $name, $value ) = @_;
            return not Email::Valid->address($value);
        }
    );
}

1;
