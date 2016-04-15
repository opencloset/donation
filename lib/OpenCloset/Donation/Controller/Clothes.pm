package OpenCloset::Donation::Controller::Clothes;
use Mojo::Base 'Mojolicious::Controller';

use Try::Tiny;

use OpenCloset::Donation::Category;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 add

    # clothes.add
    GET /users/:id/donations/:donation_id/clothes/new

=cut

sub add {
    my $self     = shift;
    my $user     = $self->stash('user');
    my $donation = $self->stash('donation');

    my $form = $donation->donation_forms->next;
    my $categories = $self->schema->resultset('Clothes')->search( undef, { group_by => 'category', select => ['category'] } );

    my $clothes1 = $donation->clothes( { status_id => { 'NOT IN' => [ 45, 46, 47 ] } }, { order_by => 'category' } );
    my $clothes2 = $donation->clothes( { status_id => 45 },                             { order_by => 'category' } );
    my $clothes3 = $donation->clothes( { status_id => 46 },                             { order_by => 'category' } );
    my $clothes4 = $donation->clothes( { status_id => 47 },                             { order_by => 'category' } );
    $self->render(
        form     => $form, categories => $categories, clothes1 => $clothes1, clothes2 => $clothes2, clothes3 => $clothes3,
        clothes4 => $clothes4
    );
}

=head2 create

    # clothes.create
    POST /users/:id/donations/:donation_id/clothes

=cut

sub create {
    my $self     = shift;
    my $user     = $self->stash('user');
    my $donation = $self->stash('donation');

    my $categories = $self->schema->resultset('Clothes')->search( undef, { group_by => 'category', select => ['category'] } );
    my @categories;
    while ( my $row = $categories->next ) {
        push @categories, $row->category;
    }

    my $v = $self->validation;
    $v->required('discard');

    my $discard = $v->param('discard');

    if ($discard) {
        $v->optional('code');
        $v->optional('gender');
    }
    else {
        $v->required('code')->like(qr/^[A-Z0-9]{4,5}$/);
        $v->required('gender')->in(qw/male female unisex/);
    }

    $v->required('status-id');
    $v->required('category')->in(@categories);
    $v->optional('color');

    ## TODO: category 별 size validation
    $v->optional('neck')->size( 2, 3 );
    $v->optional('bust')->size( 2, 3 );
    $v->optional('waist')->size( 2, 3 );
    $v->optional('hip')->size( 2, 3 );
    $v->optional('topbelly')->size( 2, 3 );
    $v->optional('belly')->size( 2, 3 );
    $v->optional('arm')->size( 2, 3 );
    $v->optional('thigh')->size( 2, 3 );
    $v->optional('length')->size( 2, 3 );
    $v->optional('foot')->size( 3, 3 );
    $v->optional('cuff')->size( 2, 3 );

    $v->optional('comment');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $status_id = $v->param('status-id');
    my $category  = $v->param('category');
    my $code      = $v->param('code');
    my $gender    = $v->param('gender');
    my $color     = $v->param('color');

    my $neck     = $v->param('neck');
    my $bust     = $v->param('bust');
    my $waist    = $v->param('waist');
    my $hip      = $v->param('hip');
    my $topbelly = $v->param('topbelly');
    my $belly    = $v->param('belly');
    my $arm      = $v->param('arm');
    my $thigh    = $v->param('thigh');
    my $cuff     = $v->param('cuff');
    my $length   = $v->param('length') || $v->param('foot');

    my $comment = $v->param('comment');

    $code = $self->generate_discard_code($category) if $discard;
    $code = sprintf( '%05s', $code );
    return $self->error( 500, "Failed to generate discard clothes code($category)" ) unless $code;

    my $clothes = $self->schema->resultset('Clothes')->find( { code => $code } );
    return $self->error( 400, "Duplicate clothes code: $code" ) if $clothes;

    my $price = $OpenCloset::Donation::Category::PRICE{$category};

    ## transaction
    my $guard = $self->schema->txn_scope_guard;
    try {
        my $group_id;
        if ( my $clothes = $donation->clothes->next ) {
            $group_id = $clothes->group_id;
        }

        unless ($group_id) {
            my $group = $self->schema->resultset('Group')->create( {} );
            $group_id = $group->id;
        }

        my $clothes = $self->schema->resultset('Clothes')->create(
            {
                donation_id => $donation->id,
                status_id   => $status_id,
                group_id    => $group_id,
                code        => $code,
                neck        => $neck,
                bust        => $bust,
                waist       => $waist,
                hip         => $hip,
                topbelly    => $topbelly,
                belly       => $belly,
                arm         => $arm,
                thigh       => $thigh,
                length      => $length,
                cuff        => $cuff,
                color       => $color,
                gender      => $gender,
                category    => $category,
                price       => $price,
                comment     => $comment
            }
        );

        die "Failed to create a new clothes" unless $clothes;

        if ( $status_id =~ /^4[567]$/ ) {
            my $clothes_code = $self->schema->resultset('ClothesCode')->find( { category => $category } );
            die "Not found category: $category" unless $clothes_code;

            $clothes_code->update( { code => sprintf( '%05s', $code ) } );
        }

        $guard->commit;
    }
    catch {
        my $err = $_;
        $self->log->error("Transaction error: clothes.create");
        $self->log->error($err);

        return $self->error( 500, $err );
    };

    $self->redirect_to('clothes.add');
}

1;
