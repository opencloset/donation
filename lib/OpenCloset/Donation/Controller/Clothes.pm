package OpenCloset::Donation::Controller::Clothes;
use Mojo::Base 'Mojolicious::Controller';

use Data::Pageset;
use List::Util qw/uniq/;
use Try::Tiny;

use OpenCloset::Constants::Category;
use OpenCloset::Constants::Status qw/$REPAIR/;

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

    my $form     = $donation->donation_forms->next;
    my $clothes1 = $donation->clothes( { status_id => { 'NOT IN' => [ 45, 46, 47 ] } }, { order_by => 'category' } );
    my $clothes2 = $donation->clothes( { status_id => 45 }, { order_by => 'category' } );
    my $clothes3 = $donation->clothes( { status_id => 46 }, { order_by => 'category' } );
    my $clothes4 = $donation->clothes( { status_id => 47 }, { order_by => 'category' } );

    my $all_clothes = $donation->clothes;
    my $msg         = $self->render_to_string(
        'sms/clothes_info', format => 'txt', all => $all_clothes, available => $clothes1,
        status_in_45 => $clothes2, status_in_46 => $clothes3, status_in_47 => $clothes4
    );
    chomp $msg;

    $self->render(
        form     => $form,     clothes1 => $clothes1, clothes2 => $clothes2, clothes3 => $clothes3,
        clothes4 => $clothes4, sms_body => $msg
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

    my @categories = @OpenCloset::Constants::Category::ALL;

    my $v = $self->validation;
    $v->required('discard');

    my $discard = $v->param('discard');

    if ($discard) {
        $v->optional('code');
        $v->optional('gender');
    }
    else {
        $v->required('code')->like(qr/^[a-zA-Z0-9]{4,5}$/);
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
    $v->optional('arm')->size( 1, 3 );
    $v->optional('thigh')->size( 2, 3 );
    $v->optional('length')->size( 2, 3 );
    $v->optional('foot')->size( 3, 3 );
    $v->optional('cuff')->like(qr/^\d{1,3}(\.)?(\d{1,2})?$/);

    $v->optional('comment');
    $v->optional('quantity')->like(qr/^\d+$/);
    $v->optional('tags');

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

    my $comment  = $v->param('comment');
    my $quantity = $v->param('quantity');
    my $tags     = $v->param('tags');

    $tags =~ s/,/ /g if $tags;

    my $input = {
        donation_id => $donation->id,
        status_id   => $status_id,
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
        price       => $OpenCloset::Constants::Category::PRICE{$category},
        comment     => $comment
    };

    if ( $discard && $quantity ) {
        for ( 1 .. $quantity ) {
            my $success = $self->_create_clothes( $donation, $discard, $input, $tags );
            return unless $success;
        }
    }
    else {
        my $success = $self->_create_clothes( $donation, $discard, $input, $tags );
        return unless $success;
    }

    $self->redirect_to('clothes.add');
}

=head2 repair_list

    # repair_clothes
    GET /clothes/repair

=cut

sub repair_list {
    my $self          = shift;
    my $page          = $self->param('p') || 1;
    my $q             = $self->param('q');
    my $alteration_at = $self->param('alteration_at');
    my $session       = $self->session;

    my $cond;
    my $attr = {
        rows     => 15,
        page     => $page,
        order_by => [qw/repair_clothes.done repair_clothes.alteration_at/],
        join     => 'repair_clothes'
    };

    ## TODO: cookie 를 공유하기 때문에 service 별 namespace 를 붙이는 것이 좋겠다
    if ($q) {
        $q = sprintf( '%05s', uc $q );
        return $self->error( 400, 'Not supported category' ) unless $q =~ /^0[JPK]/;

        my @repair_list = uniq( @{ $session->{donation}{repair_list} ||= [] }, $q );
        $session->{donation}{repair_list} = [@repair_list];

        $cond = { code => { -in => [@repair_list] } };
    }
    elsif ($alteration_at) {
        $cond = { 'repair_clothes.alteration_at' => $alteration_at };
    }
    else {
        delete $session->{donation}{repair_list};

        $cond = {
            -and => [
                category => { -in => [ $PANTS, $SKIRT ] },
                -or      => [
                    status_id           => $REPAIR,
                    'repair_clothes.id' => { '!=' => undef },
                ]
            ]
        };
    }

    my $rs = $self->schema->resultset('Clothes')->search( $cond, $attr );
    my $pageset = Data::Pageset->new(
        {
            total_entries    => $rs->pager->total_entries,
            entries_per_page => $rs->pager->entries_per_page,
            pages_per_set    => 5,
            current_page     => $page,
        }
    );

    my $summary = $self->schema->resultset('RepairClothes')->search(
        {
            alteration_at => { '!=' => undef },
            -or           => [
                { done => undef },
                { done => 1 },
            ]
        },
        {
            select => [
                'alteration_at',
                { count => '*', -as => 'sum' }
            ],
            group_by => 'alteration_at'
        }
    );

    $self->render( clothes => $rs, pageset => $pageset, summary => $summary );
}

=sub _create_clothes

    $self->_create_clothes($donation, $discard, $input, $tags?)

=cut

sub _create_clothes {
    my ( $self, $donation, $discard, $input, $tags ) = @_;

    my $code     = $input->{code};
    my $category = $input->{category};
    $code = $self->generate_discard_code($category) if $discard;
    $code = sprintf( '%05s', uc $code );
    unless ($code) {
        $self->error( 500, "Failed to generate discard clothes code($category)" ) unless $code;
        return;
    }

    my $clothes = $self->schema->resultset('Clothes')->find( { code => $code } );
    if ($clothes) {
        $self->error( 400, "Duplicate clothes code: $code" );
        return;
    }

    $input->{code} = $code;

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

        $input->{group_id} = $group_id;
        my $clothes = $self->schema->resultset('Clothes')->create($input);

        die "Failed to create a new clothes" unless $clothes;

        if ( $input->{status_id} =~ /^4[567]$/ ) {
            my $clothes_code = $self->schema->resultset('ClothesCode')->find( { category => $category } );
            die "Not found category: $category" unless $clothes_code;

            $clothes_code->update( { code => sprintf( '%05s', $code ) } );
        }

        if ($tags) {
            my @tags = split / /, $tags;
            for my $name (@tags) {
                my $tag = $self->schema->resultset('Tag')->find_or_create( { name => $name } );
                $clothes->create_related( 'clothes_tags', { tag_id => $tag->id } );
            }
        }

        $guard->commit;
    }
    catch {
        my $err = $_;
        $self->log->error("Transaction error: clothes.create");
        $self->log->error($err);

        $self->error( 500, $err );
        return;
    };

    return 1;
}

1;
