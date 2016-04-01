package OpenCloset::Donation::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::URL;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 auth

    under /forms
    under /sms
    under /users

=cut

sub auth {
    my $self = shift;

    unless ( $self->session('access_token') ) {
        my $login = Mojo::URL->new( $self->config->{opencloset}{login} );
        $login->query( return => $self->req->url->to_abs );
        $self->redirect_to($login);
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

=head2 _search_cond

    my $cond = $self->_search_cond($q);

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
