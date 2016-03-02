package OpenCloset::Donation::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';

use Data::Pageset;
use DateTime;

use OpenCloset::Donation::Status;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 prefetch

    under /forms

=cut

sub prefetch {
    my $self = shift;

    my $new       = $self->schema->resultset('DonationForm')->search( { status => undef } )->count;
    my $requested = $self->schema->resultset('DonationForm')->search( { status => $OpenCloset::Donation::Status::RETURN_REQUESTED } )->count;
    $self->stash( new => $new, return_requested => $requested );
    return 1;
}

=head2 list

    # forms
    GET /forms

=cut

sub list {
    my $self = shift;
    my $p    = $self->param('p') || 1;
    my $s    = $self->param('s') || '';
    my $q    = $self->param('q');

    my $cond = $q ? $self->_search_cond($q) : $s eq '' ? undef : { status => $s eq 'null' ? undef : $s };
    my $attr = { page => $p, rows => 20, order_by => { -desc => 'update_date' } };

    if ( $s eq $OpenCloset::Donation::Status::RETURN_REQUESTED ) {
        $attr->{order_by} = 'return_date';
    }

    my $rs      = $self->schema->resultset('DonationForm')->search( $cond, $attr );
    my $pager   = $rs->pager;
    my $pageset = Data::Pageset->new(
        {
            total_entries    => $pager->total_entries,
            entries_per_page => $pager->entries_per_page,
            pages_per_set    => 5,
            current_page     => $p,
        }
    );

    $self->render( forms => $rs, pageset => $pageset );
}

=head2 form

    # form
    GET /forms/:id

=cut

sub form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $user = $self->schema->resultset('User')->find( { email => $form->email } );
    unless ($user) {
        my $user_info = $self->schema->resultset('UserInfo')->find( { phone => $form->phone } );
        $user = $user_info->user if $user_info;
    }
    $self->render( form => $form, user => $user );
}

=head2 update_form

    # form.update
    PUT  /forms/:id
    POST /forms/:id

=cut

sub update_form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $v = $self->validation;
    $v->optional('status')->in(@OpenCloset::Donation::Status::ALL);
    $v->optional('parcel-service');
    $v->optional('waybill')->like(qr/^\d+$/);
    $v->optional('sms_bitmask')->like(qr/^\d+$/);
    $v->optional('comment');

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $input = $v->input;
    $input->{parcel_service} = delete $input->{'parcel-service'} if defined $input->{'parcel-service'};

    if ( defined $input->{status} ) {
        my $status = delete $input->{status};
        $self->update_status( $form, $status );
    }

    $form->update($input);
    $self->res->headers->location( $self->url_for( 'form', id => $id ) );
    $self->respond_to( html => sub { shift->redirect_to('form') }, json => { json => { $form->get_columns } } );
}

=head2 sendback

    # form.return
    GET /forms/:id/return

=cut

sub sendback {
    my $self       = shift;
    my $id         = $self->param('id');
    my $authorized = $self->param('authorized');

    return $self->error( 401, "Authorize required" ) unless $authorized;

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $now = DateTime->now( time_zone => 'Asia/Seoul' );
    $self->render( form => $form, holidays => [ $self->holidays( $now->year ) ] );
}

=head2 create_sendback

    POST /forms/:id/return

=cut

sub create_sendback {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $v = $self->validation;
    $v->required('return-date')->like(qr/^\d{4}-\d{2}-\d{2}$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $input = $v->input;
    $input->{return_date} = delete $input->{'return-date'} if defined $input->{'return-date'};
    $form->update($input);

    ## This method can also be used to refresh from storage, retrieving any
    ## changes made since the row was last read from storage.
    $form->discard_changes;

    $self->update_status( $form, $OpenCloset::Donation::Status::RETURN_REQUESTED );
    $self->res->headers->location( $self->url_for( 'form', id => $id ) );
    $self->respond_to(
        html => sub {
            my $self = shift;
            my $url = $self->url_for('form.return.done')->query( 'authorized' => 1 );
            $self->redirect_to($url);
        },
        json => { json => { return_date => $form->return_date } }
    );
}

=head2 sendback_done

    # form.return.done
    POST /forms/:id/return/done

=cut

sub sendback_done {
    my $self       = shift;
    my $id         = $self->param('id');
    my $authorized = $self->param('authorized');

    return $self->error( 401, "Authorize required" ) unless $authorized;

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    $self->render( form => $form );
}

=head2 _search_cond($q)

=cut

sub _search_cond {
    my ( $self, $q ) = @_;

    return {} unless length $q > 1;

    my @or;
    if ( $q =~ /^[0-9\-]+$/ ) {
        $q =~ s/-//g;
        push @or, { 'phone'   => { like => "%$q%" } };
        push @or, { 'waybill' => { like => "%$q%" } };
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
        push @or, { name => { like => "%$q%" } };
    }

    return { -or => [@or] };
}

1;
