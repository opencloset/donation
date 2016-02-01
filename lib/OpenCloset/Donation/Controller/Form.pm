package OpenCloset::Donation::Controller::Form;
use Mojo::Base 'Mojolicious::Controller';

use Data::Pageset;

has schema => sub { shift->app->schema };

=head1 METHODS

=head2 list

    # forms
    GET /forms

=cut

sub list {
    my $self = shift;
    my $p    = $self->param('p') || 1;
    my $s    = $self->param('s') || '';
    my $q    = $self->param('q');

    my $cond = $s eq '' ? {} : { status => $s };
    my $attr = { page => $p, rows => 20, order_by => { -desc => 'update_date' } };
    $s = undef if $s eq 'null';

    $cond = $self->_search_cond($q) if $q;
    my $rs = $self->schema->resultset('DonationForm')->search( $cond, $attr );

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

    $self->render( form => $form );
}

=head2 update_form

    # form.update
    POST /forms/:id

=cut

sub update_form {
    my $self = shift;
    my $id   = $self->param('id');

    my $form = $self->schema->resultset('DonationForm')->find($id);
    return $self->error( 404, "Form not found: $id" ) unless $form;

    my $v = $self->validation;
    $v->optional('parcel-service');
    $v->optional('waybill')->like(qr/^\d+$/);

    if ( $v->has_error ) {
        my $failed = $v->failed;
        return $self->error( 400, 'Parameter Validation Failed: ' . join( ', ', @$failed ) );
    }

    my $parcel_service = $v->param('parcel-service');
    my $waybill        = $v->param('waybill');

    $form->update( { parcel_service => $parcel_service, waybill => $waybill, status => 'sent' } );
    $self->redirect_to('form');
}

=head2 _search_cond($q)

=cut

sub _search_cond {
    my ( $self, $q ) = @_;

    return {} unless length $q > 1;

    my @or;
    if ( $q =~ /^[0-9\-]+$/ ) {
        $q =~ s/-//g;
        push @or, { 'phone' => { like => "%$q%" } };
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
