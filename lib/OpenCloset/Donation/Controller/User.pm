package OpenCloset::Donation::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;
use Try::Tiny;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 auth

    under /forms
    under /sms
    under /users

=cut

sub auth {
    my $self = shift;

    my $user_id = $self->session('access_token');
    unless ($user_id) {
        my $login = Mojo::URL->new( $self->config->{opencloset}{login} );
        $login->query( return => $self->req->url->to_abs );
        $self->redirect_to($login);
        return;
    }

    my $user = $self->schema->resultset('User')->find( { id => $user_id } );
    return unless $user;

    my $user_info = $user->user_info;
    unless ( $user_info->staff ) {
        my $email = $user->email;
        $self->log->warn("oops! $email is not a staff");
        return;
    }
    return 1;
}

=head2 list

    GET /users?q=:query

=cut

sub list {
    my $self = shift;
    my $q    = $self->param('q');

    my $cond = $self->_search_cond($q);
    my $rs = $self->schema->resultset('User')->search( $cond, { join => 'user_info', rows => 10 } );

    $self->render( users => $rs );
}

=head2 prefetch_user

    under /users/:id

=cut

sub prefetch_user {
    my $self = shift;
    my $id   = $self->param('id');

    my $user = $self->schema->resultset('User')->find( { id => $id } );
    unless ($user) {
        $self->error( 404, "User not found" );
        return;
    }

    $self->stash( user => $user );
    return 1;
}

=head2 donations

    GET /users/:id/donations

=cut

sub donations {
    my $self      = shift;
    my $user      = $self->stash('user');
    my $user_info = $user->user_info;

    my $forms = $self->schema->resultset('DonationForm')->search( { -or => [ { email => $user->email }, { phone => $user_info->phone } ] } );

    my %categories;
    my $donations = $user->donations( undef, { order_by => { -desc => 'create_date' } } );
    while ( my $donation = $donations->next ) {
        my $clothes = $donation->clothes;
        while ( my $row = $clothes->next ) {
            my $category = $row->category;
            $categories{$category}++;
        }
    }

    $self->render( categories => \%categories, donations => $donations->reset, forms => $forms );
}

=head2 add_donation

    # user.donations.add
    GET /users/:id/donations/new

=cut

sub add_donation {
    my $self    = shift;
    my $form_id = $self->param('form_id');

    my $form;
    if ($form_id) {
        $form = $self->schema->resultset('DonationForm')->find($form_id);
        return $self->error( 404, "Form not found: $form_id" ) unless $form;
    }

    $self->render( form => $form );
}

=head2 create_donation

    # user.donations.create
    POST /users/:id/donations

=cut

sub create_donation {
    my $self = shift;
    my $user = $self->stash('user');

    my $v = $self->validation;
    $v->optional('message');
    $v->optional('form_id');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $message = $v->param('message');
    my $form_id = $v->param('form_id');

    ## transaction
    my $guard = $self->schema->txn_scope_guard;
    my $donation;
    try {
        $donation = $self->schema->resultset('Donation')->create(
            {
                user_id => $user->id,
                message => $message,
            }
        );

        die "Failed to create a new donation" unless $donation;

        if ($form_id) {
            my $form = $self->schema->resultset('DonationForm')->find($form_id);
            die "Form not found: $form_id" unless $form;

            $form->update( { donation_id => $donation->id } );
        }

        $guard->commit;
    }
    catch {
        my $err = $_;
        $self->log->error("Transaction error: user.donations.create");
        $self->log->error($err);

        return $self->error( 500, $err );
    };

    $self->redirect_to( 'clothes.add', donation_id => $donation->id );
}

=head2 prefetch_donation

    under /users/:id/donations/:donation_id

=cut

sub prefetch_donation {
    my $self = shift;
    my $id   = $self->param('donation_id');

    my $donation = $self->schema->resultset('Donation')->find( { id => $id } );
    unless ($donation) {
        $self->error( 404, "Donation not found: $id" );
        return;
    }

    $self->stash( donation => $donation );
    return 1;
}

=head2 _search_cond

    my $cond = $self->_search_cond($q);
    my $rs   = $self->schema->resultset('User')->search( $cond, $attr );

=cut

sub _search_cond {
    my $self = shift;
    my $q = $self->param('q') || '';

    return unless $q;
    return unless length $q > 1;

    my @or;
    if ( $q =~ /^[0-9\-]+$/ ) {
        $q =~ s/-//g;
        push @or, { 'user_info.phone' => { like => "%$q%" } };
    }
    elsif ( $q =~ /^[a-zA-Z0-9_\-]+/ ) {
        if ( $q =~ /\@/ ) {
            push @or, { email => { like => "%$q%" } };
        }
        else {
            push @or, { email => { like => "%$q%" } };
            push @or, { name  => { like => "%$q%" } };
        }
    }
    elsif ( $q =~ m/^[ㄱ-힣]+$/ ) {
        push @or, { name => { like => "$q%" } };
    }

    return { -or => [@or] };
}

1;
