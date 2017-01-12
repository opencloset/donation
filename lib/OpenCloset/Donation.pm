package OpenCloset::Donation;
use Mojo::Base 'Mojolicious';

use Email::Valid ();
use HTTP::Body::Builder::MultiPart;
use HTTP::Tiny;

use OpenCloset::Schema;

use version; our $VERSION = qv("v0.4.1");

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
    $self->plugin( Minion => { SQLite => $self->config->{minion}{SQLite} } );
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
    $self->_add_task;
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

    my $prefetch_form = $r->under('/forms/:id')->to('form#prefetch_form');
    $prefetch_form->get('/return')->to('form#sendback')->name('form.return');
    $prefetch_form->post('/return')->to('form#create_sendback');
    $prefetch_form->get('/return/done')->to('form#sendback_done')->name('form.return.done');
}

sub _private_routes {
    my $self = shift;
    my $r    = $self->routes;

    my $forms   = $r->under('/forms')->to('user#auth')->name('auth');
    my $sms     = $r->under('/sms')->to('user#auth');
    my $users   = $r->under('/users')->to('user#auth');
    my $clothes = $r->under('/clothes')->to('user#auth');

    $forms = $forms->under('/')->to('form#prefetch_status');
    $forms->get('/')->to('form#list')->name('forms');

    my $form = $forms->under('/:id')->to('form#prefetch_form');
    $form->get('/')->to('form#form')->name('form');
    $form->any( [ 'POST', 'PUT' ] => '/' )->to('form#update_form')->name('form.update');

    $sms->post('/')->to('API#create_sms')->name('sms.create');

    $users->get('/')->to('user#list')->name('users');
    $users->post('/')->to('API#create_user')->name('user.create');

    my $user = $users->under('/:id')->to('user#prefetch_user');
    $user->get('/donations')->to('user#donations')->name('user.donations');
    $user->get('/donations/new')->to('user#add_donation')->name('user.donations.add');
    $user->post('/donations')->to('user#create_donation')->name('user.donations.create');

    my $donation = $user->under('/donations/:donation_id')->to('user#prefetch_donation');
    $donation->get('/clothes/new')->to('clothes#add')->name('clothes.add');
    $donation->post('/clothes')->to('clothes#create')->name('clothes.create');

    $clothes->get('/repair')->to('Clothes#repair_list')->name('repair_clothes');
    $clothes->put('/repair/:code')->to('API#repair_clothes')->name('clothes.repair');
    $clothes->get('/code')->to('API#code');
    $clothes->get('/:code/suggestion')->to('API#suggestion_resize')->name('clothes.resize.suggestion');
    $clothes->put('/:code/suggestion')->to('API#update_resize')->name('clothes.resize.update');
    $clothes->get('/tags')->to('Clothes#tags')->name('clothes.tags');
    $clothes->get('/:code/tags')->to('API#clothes_tags')->name('clothes.code.tags');
    $clothes->put('/')->to('API#update_clothes')->name('clothes.update');
    $clothes->post('/tags')->to('API#create_clothes_tag')->name('clothes.create.tag');
    $clothes->delete('/tags')->to('API#delete_clothes_tag')->name('clothes.delete.tag');

    $r->post('/suit')->to('API#create_suit')->name('suit.create');
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

sub _add_task {
    my $self   = shift;
    my $minion = $self->minion;
    $minion->add_task(
        upload_clothes_photo => sub {
            my ( $job, $key, $img ) = @_;
            return unless $key;
            return unless $img;

            my $app     = $job->app;
            my $oavatar = $app->config->{oavatar};
            my ( $token, $url ) = ( $oavatar->{token}, $oavatar->{url} );
            my $multipart = HTTP::Body::Builder::MultiPart->new;
            $multipart->add_content( token => $token );
            $multipart->add_content( key   => $key );
            $multipart->add_file( img => $img );

            my $http = HTTP::Tiny->new;
            my $res  = $http->request(
                'POST', $url,
                {
                    headers => { 'content-type' => 'multipart/form-data; boundary=' . $multipart->{boundary} },
                    content => $multipart->as_string
                }
            );

            unless ( $res->{success} ) {
                $app->log->error("Failed to upload a oavatar: $res->{reason}");
            }
            else {
                $app->log->info("Photo uploaded: $res->{headers}{location}");
            }

            $img->remove;
        }
    );
}

1;
